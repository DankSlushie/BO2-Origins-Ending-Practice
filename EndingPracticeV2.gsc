#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zm_tomb_dig;
#include maps\mp\zm_tomb_utility;
#include maps\mp\zm_tomb_craftables;
#include maps\mp\zm_tomb_teleporter;
#include maps\mp\zm_tomb_main_quest;
#include maps\mp\zm_tomb_giant_robot;
#include maps\mp\zm_tomb_capture_zones;
#include maps\mp\zombies\_zm_perks;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_powerups;
#include maps\mp\zombies\_zm_ai_mechz;
#include maps\mp\zombies\_zm_equipment;
#include maps\mp\zombies\_zm_craftables;
#include maps\mp\zombies\_zm_weap_beacon;
#include maps\mp\zombies\_zm_weap_claymore;
#include maps\mp\zombies\_zm_weap_one_inch_punch;

main() {
    replaceFunc(maps\mp\zm_tomb_dig::waittill_dug, ::waittillDug);
    replaceFunc(maps\mp\zm_tomb_giant_robot::robot_cycling, ::robotCycling);
    replaceFunc(maps\mp\zm_tomb_giant_robot::giant_robot_start_walk, ::giantRobotStartWalk);
    replaceFunc(maps\mp\zm_tomb_main_quest::staff_biplane_drop_pieces, ::staffBiplaneDropPieces);
    replaceFunc(maps\mp\zm_tomb_capture_zones::recapture_round_tracker, ::recaptureRoundTracker);
    replaceFunc(maps\mp\zombies\_zm_ai_mechz::mechz_round_tracker, ::mechzRoundTracker);
    replaceFunc(maps\mp\zombies\_zm_powerups::get_next_powerup, ::getNextPowerup);
}

init() {
    createDvar("EndingPractice_round", 16);
    createDvar("EndingPractice_stg", 1);
    createDvar("EndingPractice_gram", 1);
    createDvar("EndingPractice_foot", 0);

    level thread onPlayerConnect();
    level thread initEndingPractice();
    level thread chatMonitor();
    level thread spawnDelayFix();
}

onPlayerConnect() {
    self endon("end_game");
    for (;;) {
        self waittill("connected", player);
        player thread onPlayerSpawned();
    }
}

onPlayerSpawned() {
    level endon("end_game");
    self endon("disconnect");

    for (;;) {
        self waittill("spawned_player");

        flag_wait("initial_blackscreen_passed");

        self.score = 100000;

        self giveShovel();
        self claymore_setup();
        self player_give_beacon();

        self upgradeWeapon();
        self giveWeapon("mp44_zm");
        if (getDvarInt("EndingPractice_stg") != 0) {
            self switchToWeapon("mp44_zm");
            wait 1;
            self upgradeWeapon();
        }

        self give_perk("specialty_longersprint");
        wait 0.2;
        self give_perk("specialty_armorvest");
        wait 0.2;
        self give_perk("specialty_additionalprimaryweapon");
        wait 0.2;
        self give_perk("specialty_rof");

        self thread one_inch_punch_melee_attack();
        self thread takeMaxis();
        self thread takeUpgradedStaff(1);
        self thread timer();

        self teleportPlayer((-2618.15, 547.033, 213.615), (0, 180, 0));
    }
}

initEndingPractice() {
    self endon("end_game");

    flag_wait("initial_blackscreen_passed");

    thread printMessage();
    thread openAllDoors();
    thread takeAllParts();
    thread craftMaxisAtWind();
    thread spawnAllDigs();
    thread placeStaffsInChargers();
    thread setRound();

    activateGenerators();
    openChamber();
    openPortals();

    flag_set("ee_all_staffs_crafted");
    flag_set("ee_all_staffs_placed");

    level.mechz_should_drop_powerup = 1;
    level.zombie_vars["zombie_powerup_drop_increment"] = 7414.44;
}

chatMonitor() {
    self endon("end_game");
    for (;;) {
        level waittill("say", message, player);

        if (message == "15") {
            setDvar("EndingPractice_round", 15);
            printDvar("EndingPractice_round");

        } else if (message == "16") {
            setDvar("EndingPractice_round", 16);
            printDvar("EndingPractice_round");

        } else if (message == "stg") {
            toggleDvar("EndingPractice_stg");
            printDvar("EndingPractice_stg");

        } else if (message == "gram") {
            toggleDvar("EndingPractice_gram");
            printDvar("EndingPractice_gram");

        } else if (message == "random") {
            setDvar("EndingPractice_foot", 0);
            printDvar("EndingPractice_foot");

        } else if (message == "left") {
            setDvar("EndingPractice_foot", 1);
            printDvar("EndingPractice_foot");
            
        } else if (message == "right") {
            setDvar("EndingPractice_foot", 2);
            printDvar("EndingPractice_foot");
        }
    }
}

spawnDelayFix() {
    self endon("end_game");
    for (;;) {
        level waittill("start_of_round");
        delay = 2;
        for (i = 2; i <= level.round_number; i++) {
            delay *= 0.95;
        }
        level.zombie_vars["zombie_spawn_delay"] = delay;
    }
}

placeStaffsInChargers() {
    level waittill("allPartsTaken");
    p = getPlayers()[0];
    for (i = 1; i <= 4; i++) {
        level notify("player_teleported", p, i);
        flag_set("charger_ready_" + i);
        wait 0.5;
    }
    foreach (staff in level.a_elemental_staffs) {        
        staff.charger.is_inserted = 1;
        maps\mp\zm_tomb_craftables::clear_player_staff( staff.weapname );
        staff.charge_trigger trigger_off();
        if ( isdefined( staff.charger.angles ) )
            staff.angles = staff.charger.angles;
        staff moveto( staff.charger.origin, 0.05 );
        staff waittill( "movedone" );
        staff setclientfield( "staff_charger", staff.enum );
        staff.charger.full = 0;
        staff show();
        staff playsound( "zmb_squest_charge_place_staff" );
        flag_set(staff.weapname + "_upgrade_unlocked");
        staff.charger.charges_received = 20;
    }
}

takeUpgradedStaff(enum) {
    flag_wait("ee_all_staffs_upgraded");
    wait 1;
    staff = get_staff_info_from_element_index(enum);
    staff.upgrade.trigger notify("trigger", self);
}

createDvar(dvar, set) {
    if (getDvar(dvar) == "") {
        setDvar(dvar, set);
    }
}

toggleDvar(dvar) {
    setDvar(dvar, (getDvarInt(dvar) + 1) % 2);
}

printDvar(dvar) {
    iprintln(dvar + ": " + getDvar(dvar));
}

printMessage() {
    iprintln("^6EndingPracticeV2 ^7by ^5DankSlushie");
    iprintln("https://github.com/DankSlushie/BO2-Origins-Ending-Practice");
    wait 5;
    printDvar("EndingPractice_round");
    wait 0.5;
    printDvar("EndingPractice_stg");
    wait 0.5;
    printDvar("EndingPractice_gram");
    wait 0.5;
    printDvar("EndingPractice_foot");
}

setRound() {
    level waittill("start_of_round");
    r = getDvarInt("EndingPractice_round");
    if (r > 3 && r < 200) {
        level.zombie_total = 0;
        maps\mp\zombies\_zm::ai_calculate_health(r);
        level.round_number = r - 1;
        wait 1;
        zombies = get_round_enemy_array();
        if (isDefined(zombies)) {
            for (i = 0; i < zombies.size; i++) {
                zombies[i] dodamage(zombies[i].health + 666, zombies[i].origin);
            }
        }
    }
}

spawnAllDigs() {
    a_dig_spots = array_randomize(level.a_dig_spots);
    for (i = 0; i < a_dig_spots.size; i++) {
        if (isDefined(a_dig_spots[i].dug) && a_dig_spots[i].dug) {
            a_dig_spots[i].dug = undefined;
            a_dig_spots[i] thread dig_spot_spawn();
            wait_network_frame();
        }
    }
}

teleportPlayer(origin, angles) {
    self setOrigin(origin);
    self setPlayerAngles(angles);
}

takeAllParts() {
    p = getPlayers()[0];
    foreach ( craftable in level.a_uts_craftables ) {
        foreach ( piece in craftable.craftablespawn.a_piecespawns ) {
            p player_take_piece(piece);
            wait 0.1;
        }
    }

    p player_drop_piece();

    level notify("allPartsTaken");
}

craftMaxisAtWind() {
    level waittill("allPartsTaken");

    maxis = find_craftable_stub("equip_dieseldrone_zm");
    
    t = level.a_uts_craftables[1];
    t.a_uts_open_craftables_available = [];
    t.a_uts_open_craftables_available[0] = maxis;
    t.n_open_craftable_choice = 0;
    t.equipname = maxis.equipname;
    t.hint_string = maxis.hint_string;

    t.hint_string = getPlayers()[0] player_craft(t.craftablespawn);
    level.quadrotor_status.pickup_trig = t;
    t [[ t.craftablestub.onfullycrafted ]]();

    wait 1;

    level notify("maxisCraftedAtWind");
}

takeMaxis() {
    level waittill("maxisCraftedAtWind");
    setup_quadrotor_purchase(self);
}

openAllDoors() {
    setdvar( "zombie_unlock_all", 1 );
    flag_set( "power_on" );
    players = get_players();
    zombie_doors = getentarray( "zombie_door", "targetname" );

    for ( i = 0; i < zombie_doors.size; i++ )
    {
        zombie_doors[i] notify( "trigger", players[0] );

        if ( is_true( zombie_doors[i].power_door_ignore_flag_wait ) )
            zombie_doors[i] notify( "power_on" );

        wait 0.05;
    }

    zombie_airlock_doors = getentarray( "zombie_airlock_buy", "targetname" );

    for ( i = 0; i < zombie_airlock_doors.size; i++ )
    {
        zombie_airlock_doors[i] notify( "trigger", players[0] );
        wait 0.05;
    }

    zombie_debris = getentarray( "zombie_debris", "targetname" );

    for ( i = 0; i < zombie_debris.size; i++ )
    {
        zombie_debris[i] notify( "trigger", players[0] );
        wait 0.05;
    }

    level notify( "open_sesame" );
    wait 1;
    setdvar( "zombie_unlock_all", 0 );
}

activateGenerators() {
    a_s_generator = getstructarray("s_generator", "targetname");

    for (i = 0; i < a_s_generator.size; i++) {
        a_s_generator[i].n_current_progress = 100;
        a_s_generator[i] handle_generator_capture();
    }
}

openChamber() {
    a_door_main = getentarray( "chamber_entrance", "targetname" );
    array_thread( a_door_main, ::runGramDoor, "vinyl_master" );
    chamber_blocker();
}

runGramDoor() {
    trig_position = getstruct( self.targetname + "_position", "targetname" );

    flag_set( self.targetname + "_opened" );

    if ( isdefined( trig_position.script_flag ) )
        flag_set( trig_position.script_flag );

    self movez( -260, 10.0, 1.0, 1.0 );

    self waittill( "movedone" );

    self connectpaths();
    self delete();
}

openPortals() {   
    portals = getstructarray("stargate_gramophone_pos", "targetname");
    if (getDvarInt("EndingPractice_gram") == 1) {
        portals[2] thread activatePortal();
    }
    portals[0] thread activatePortal();
    portals[1] thread activatePortal();
    portals[3] thread activatePortal();
}

activatePortal() {
    t_gramophone = tomb_spawn_trigger_radius(self.origin, 60, 1);
    self.gramophone_model = spawn("script_model", self.origin);
    self.gramophone_model.angles = self.angles;
    self.gramophone_model setmodel("p6_zm_tm_gramophone");
    level setclientfield("piece_record_zm_player", 0);
    // flag_set("gramophone_placed");
    t_gramophone set_unitrigger_hint_string("");
    t_gramophone trigger_off();
    stargate_teleport_enable(self.script_int);
    flag_wait("teleporter_building_" + self.script_int);
    flag_waitopen("teleporter_building_" + self.script_int);
    t_gramophone trigger_on();
    t_gramophone set_unitrigger_hint_string(&"ZM_TOMB_PUGR");
    if (isDefined(self.script_flag)) {
        flag_set(self.script_flag);
    }
}

giveShovel() {
    self.dig_vars["has_shovel"] = 1;
    n_player = self getentitynumber() + 1;
    level setclientfield( "shovel_player" + n_player, 1 );
}

upgradeWeapon() {
    baseweapon = get_base_name(self getcurrentweapon());
    weapon = getUpgrade(baseweapon);
    if (isDefined(weapon)) {
        self takeweapon(baseweapon);
        self giveweapon(weapon, 0, self get_pack_a_punch_weapon_options(weapon));
        self switchtoweapon(weapon);
        self givemaxammo(weapon);
    }
}

getUpgrade(weapon) {
    if (isDefined(level.zombie_weapons[weapon].upgrade_name) && isDefined(level.zombie_weapons[weapon]))
        return get_upgrade_weapon(weapon, 0);
    else
        return get_upgrade_weapon(weapon, 1);
}

timer() {
    self endon("disconnect");
    timer_hud = newclienthudelem(self);
	timer_hud.alignx = "center";
	timer_hud.aligny = "center";
	timer_hud.horzalign = "center";
	timer_hud.vertalign = "center";
	timer_hud.fontscale = 2;
	timer_hud.alpha = 0;
	timer_hud.color = (1, 1, 1);
	timer_hud.hidewheninmenu = 1;
	timer_hud.hidden = 0;
	timer_hud.label = &"";
	flag_wait("fire_link_enabled");
	timer_hud.alpha = 1;
	timer_hud settimerup(0);
}

// -----------------------------------------------------------------------
// -----------------------------------------------------------------------
// ------------------------ Replaced Functions ---------------------------
// -----------------------------------------------------------------------
// -----------------------------------------------------------------------

#using_animtree("zm_tomb_giant_robot_hatch");

waittillDug( s_dig_spot ) {
    for (;;) {
        self waittill( "trigger", player );

        if ( isdefined( player.dig_vars["has_shovel"] ) && player.dig_vars["has_shovel"] )
        {
            player playsound( "evt_dig" );
            s_dig_spot.dug = 1;
            level.n_dig_spots_cur--;
            playfx( level._effect["digging"], self.origin );
            player setclientfieldtoplayer( "player_rumble_and_shake", 1 );
            player maps\mp\zombies\_zm_stats::increment_client_stat( "tomb_dig", 0 );
            player maps\mp\zombies\_zm_stats::increment_player_stat( "tomb_dig" );
            
            self thread digUpBlood();

            if ( !player.dig_vars["has_upgraded_shovel"] )
            {
                player.dig_vars["n_spots_dug"]++;

                if ( player.dig_vars["n_spots_dug"] >= 30 )
                {
                    player.dig_vars["has_upgraded_shovel"] = 1;
                    player thread ee_zombie_blood_dig();
                    n_player = player getentitynumber() + 1;
                    level setclientfield( "shovel_player" + n_player, 2 );
                    player playsoundtoplayer( "zmb_squest_golden_anything", player );
                    player maps\mp\zombies\_zm_stats::increment_client_stat( "tomb_golden_shovel", 0 );
                    player maps\mp\zombies\_zm_stats::increment_player_stat( "tomb_golden_shovel" );
                }
            }

            return;
        }
    }
}

digUpBlood( player ) {
    powerup = spawn( "script_model", self.origin );
    powerup endon( "powerup_grabbed" );
    powerup endon( "powerup_timedout" );
    a_rare_powerups = dig_get_rare_powerups( player );
    powerup_item = "zombie_blood";
    player dig_reward_dialog( "dig_powerup" );

    powerup maps\mp\zombies\_zm_powerups::powerup_setup( powerup_item );
    powerup movez( 40, 0.6 );

    powerup waittill( "movedone" );

    powerup thread maps\mp\zombies\_zm_powerups::powerup_timeout();
    powerup thread maps\mp\zombies\_zm_powerups::powerup_wobble();
    powerup thread maps\mp\zombies\_zm_powerups::powerup_grab();
}

robotCycling() {
    three_robot_round = 0;
    last_robot = -1;
    level thread giant_robot_intro_walk( 1 );

    level waittill( "giant_robot_intro_complete" );

    for (;;) {
        if ( !( level.round_number % 4 ) && three_robot_round != level.round_number )
            flag_set( "three_robot_round" );

        if ( flag( "ee_all_staffs_placed" ) && !flag( "ee_mech_zombie_hole_opened" ) )
            flag_set( "three_robot_round" );

        if ( flag( "three_robot_round" ) )
        {
            level.zombie_ai_limit = 22;

            // random_number = randomint( 3 );
            random_number = 0;

            if ( random_number == 2 )
                level thread giant_robot_start_walk( 2 );
            else
                level thread giant_robot_start_walk( 2, 0 );

            wait 5;

            if ( random_number == 0 )
                level thread giant_robot_start_walk( 0 );
            else
                level thread giant_robot_start_walk( 0, 0 );

            wait 5;

            if ( random_number == 1 )
                level thread giant_robot_start_walk( 1 );
            else
                level thread giant_robot_start_walk( 1, 0 );

            level waittill( "giant_robot_walk_cycle_complete" );

            level waittill( "giant_robot_walk_cycle_complete" );

            level waittill( "giant_robot_walk_cycle_complete" );

            wait 5;
            level.zombie_ai_limit = 24;
            three_robot_round = level.round_number;
            last_robot = -1;
            flag_clear( "three_robot_round" );
        }
        else
        {
            if ( !flag( "activate_zone_nml" ) )
                random_number = randomint( 2 );
            else
            {
                do
                    random_number = randomint( 3 );
                while ( random_number == last_robot );
            }

            last_robot = random_number;
            level thread giant_robot_start_walk( random_number );

            level waittill( "giant_robot_walk_cycle_complete" );

            wait 5;
        }
    }
}

giantRobotStartWalk( n_robot_id, b_has_hatch = 1 ) {
    ai = getent( "giant_robot_walker_" + n_robot_id, "targetname" );
    level.gr_foot_hatch_closed[n_robot_id] = 1;
    ai.b_has_hatch = b_has_hatch;
    ai ent_flag_clear( "kill_trigger_active" );
    ai ent_flag_clear( "robot_head_entered" );

    if ( isdefined( ai.b_has_hatch ) && ai.b_has_hatch )
        m_sole = getent( "target_sole_" + n_robot_id, "targetname" );

    if ( isdefined( m_sole ) && ( isdefined( ai.b_has_hatch ) && ai.b_has_hatch ) )
    {
        m_sole setcandamage( 1 );
        m_sole.health = 99999;
        m_sole useanimtree( #animtree );
        m_sole unlink();
    }

    wait 10;

    if ( isdefined( m_sole ) )
    {
        dvar = getDvarInt("EndingPractice_foot");
        if (dvar == 1) {
            ai.hatch_foot = "left";
        } else if (dvar == 2) {
            ai.hatch_foot = "right";
        } else {
            if ( cointoss() )
                ai.hatch_foot = "left";
            else
                ai.hatch_foot = "right";
        }
        
        if ( ai.hatch_foot == "left" )
        {
            n_sole_origin = ai gettagorigin( "TAG_ATTACH_HATCH_LE" );
            v_sole_angles = ai gettagangles( "TAG_ATTACH_HATCH_LE" );
            ai.hatch_foot = "left";
            str_sole_tag = "TAG_ATTACH_HATCH_LE";
            ai attach( "veh_t6_dlc_zm_robot_foot_hatch", "TAG_ATTACH_HATCH_RI" );
        }
        else if ( ai.hatch_foot == "right" )
        {
            n_sole_origin = ai gettagorigin( "TAG_ATTACH_HATCH_RI" );
            v_sole_angles = ai gettagangles( "TAG_ATTACH_HATCH_RI" );
            ai.hatch_foot = "right";
            str_sole_tag = "TAG_ATTACH_HATCH_RI";
            ai attach( "veh_t6_dlc_zm_robot_foot_hatch", "TAG_ATTACH_HATCH_LE" );
        }

        m_sole.origin = n_sole_origin;
        m_sole.angles = v_sole_angles;
        wait 0.1;
        m_sole linkto( ai, str_sole_tag, ( 0, 0, 0 ) );
        m_sole show();
        ai attach( "veh_t6_dlc_zm_robot_foot_hatch_lights", str_sole_tag );
    }

    if ( !( isdefined( ai.b_has_hatch ) && ai.b_has_hatch ) )
    {
        ai attach( "veh_t6_dlc_zm_robot_foot_hatch", "TAG_ATTACH_HATCH_RI" );
        ai attach( "veh_t6_dlc_zm_robot_foot_hatch", "TAG_ATTACH_HATCH_LE" );
    }

    wait 0.05;
    ai thread giant_robot_think( ai.trig_stomp_kill_right, ai.trig_stomp_kill_left, ai.clip_foot_right, ai.clip_foot_left, m_sole, n_robot_id );
}

staffBiplaneDropPieces( a_staff_pieces ) {
}

recaptureRoundTracker() {
    n_next_recapture_round = 19;
    for (;;) {
        level waittill_any( "between_round_over", "force_recapture_start" );
        if ( level.round_number >= n_next_recapture_round && !flag( "zone_capture_in_progress" ) && get_captured_zone_count() >= get_player_controlled_zone_count_for_recapture() ) {
            n_next_recapture_round = level.round_number + randomintrange( 3, 6 );
            level thread recapture_round_start();
        }
    }
}

mechzRoundTracker() {
    maps\mp\zombies\_zm_ai_mechz_ffotd::mechz_round_tracker_start();
    level.num_mechz_spawned = 0;
    old_spawn_func = level.round_spawn_func;
    old_wait_func = level.round_wait_func;

    while ( !isdefined( level.zombie_mechz_locations ) )
        wait 0.05;

    flag_wait( "activate_zone_nml" );
    mech_start_round_num = 8;

    if ( isdefined( level.is_forever_solo_game ) && level.is_forever_solo_game )
        mech_start_round_num = 8;

    r = getDvarInt("EndingPractice_round");
    if (r > 7 && r < 200) {
        mech_start_round_num = r + 1;
    } 

    while ( level.round_number < mech_start_round_num )
        level waittill( "between_round_over" );

    level.next_mechz_round = level.round_number;
    level thread debug_print_mechz_round();

    for (;;) {
        maps\mp\zombies\_zm_ai_mechz_ffotd::mechz_round_tracker_loop_start();

        if ( level.num_mechz_spawned > 0 )
            level.mechz_should_drop_powerup = 1;

        if ( level.next_mechz_round <= level.round_number )
        {
            a_zombies = getaispeciesarray( level.zombie_team, "all" );

            foreach ( zombie in a_zombies )
            {
                if ( isdefined( zombie.is_mechz ) && zombie.is_mechz && isalive( zombie ) )
                {
                    level.next_mechz_round++;
                    break;
                }
            }
        }

        if ( level.mechz_left_to_spawn == 0 && level.next_mechz_round <= level.round_number )
        {
            mechz_health_increases();

            if ( isdefined( level.is_forever_solo_game ) && level.is_forever_solo_game )
                level.mechz_zombie_per_round = 1;
            else if ( level.mechz_round_count < 2 )
                level.mechz_zombie_per_round = 1;
            else if ( level.mechz_round_count < 5 )
                level.mechz_zombie_per_round = 2;
            else
                level.mechz_zombie_per_round = 3;

            level.mechz_left_to_spawn = level.mechz_zombie_per_round;
            mechz_spawning = level.mechz_left_to_spawn;
            wait( randomfloatrange( 10.0, 15.0 ) );
            level notify( "spawn_mechz" );

            if ( isdefined( level.is_forever_solo_game ) && level.is_forever_solo_game )
                n_round_gap = randomintrange( level.mechz_min_round_fq_solo, level.mechz_max_round_fq_solo );
            else
                n_round_gap = randomintrange( level.mechz_min_round_fq, level.mechz_max_round_fq );

            level.next_mechz_round = level.round_number + n_round_gap;
            level.mechz_round_count++;
            level thread debug_print_mechz_round();
            level.num_mechz_spawned += mechz_spawning;
        }

        maps\mp\zombies\_zm_ai_mechz_ffotd::mechz_round_tracker_loop_end();

        level waittill( "between_round_over" );

        mechz_clear_spawns();
    }
}

getNextPowerup() {
    if (flag("ee_maxis_drone_retrieved")) {
        powerup = level.zombie_powerup_array[level.zombie_powerup_index];
        level.zombie_powerup_index++;

        if ( level.zombie_powerup_index >= level.zombie_powerup_array.size )
        {
            level.zombie_powerup_index = 0;
            randomize_powerups();
        }

        return powerup;
    } else {
        return "zombie_blood";
    }
}
