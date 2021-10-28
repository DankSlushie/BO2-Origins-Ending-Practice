// g_gametype zclassic;ui_zm_gamemodegroup zclassic;ui_zm_mapstartlocation tomb;map zm_tomb

#include common_scripts/utility;
#include maps/mp/gametypes_zm/_hud_message;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zombies/_zm_utility;
#include maps/mp/zombies/_zm_weapons;
#include maps/mp/zombies/_zm_weap_beacon;
#include maps/mp/zombies/_zm_weap_claymore;
#include maps/mp/zombies/_zm_perks;
#include maps/mp/zombies/_zm;
#include maps/mp/zombies/_zm_melee_weapon;
#include maps/mp/zombies/_zm_challenges;
#include maps/mp/zombies/_zm_craftables;
#include maps/mp/zombies/_zm_unitrigger;
#include maps/mp/zombies/_zm_zonemgr;
#include maps/mp/zombies/_zm_blockers;
#include maps/mp/zombies/_zm_net;
#include maps/mp/zombies/_zm_sidequests;
#include maps/mp/zm_tomb_capture_zones;
#include maps/mp/zm_tomb_craftables;
#include maps/mp/zm_tomb_main_quest;
#include maps/mp/zm_tomb_utility;
#include maps/mp/zm_tomb_teleporter;
#include maps/mp/zm_tomb_amb;
#include maps/mp/zm_tomb_chamber;
#include maps/mp/zm_tomb_quest_crypt;
#include maps/mp/_utility;

init() {
	level thread onPlayerConnect();
}

onPlayerConnect() {
	for(;;) {
        level waittill("connected", player);

	    self thread addCheatCraftables();

		wait 10;

		player thread initEndingPractice();
	}
}

initEndingPractice() {

	iprintln("Ending Practice...");

	thread zombie_spawn_delay_fix();

	self thread pickupEverything();
	self.dig_vars[ "has_shovel" ] = 1;

	self.score = 100000;

    self give_perk("specialty_longersprint");
    wait 0.5;
    self give_perk("specialty_armorvest");
    wait 0.5;
    self give_perk("specialty_additionalprimaryweapon");
    wait 0.5;
    self give_perk("specialty_rof");

	self player_give_beacon();
    self claymore_setup();

	upgradeWeapon();

	self giveWeapon("mp44_zm");
	wait 1;
	self switchToWeapon("mp44_zm");
	wait 1;
	upgradeWeapon();

	activateGenerators();

	self increment_stat("zc_boxes_filled", 4);
	iprintln("Grab the punch");

	openAllDoors();
    openChamber();
    thread gramAtWind();
	upgradeStaffs();

	takeUpgradedFire();

	thread progressEE();
	
	level notify( "biplane_down" );

	level.force_weather[16] = "rain"; // for 5 extra dig spots

	wait 7;

	self setRound(16);

	// nml (-760.179, 1121.94, 119.175)
	// gen 5 (-2493.36, 178.245, 236.625)
	// stam (-2399.83, 3.22381, 233.342)
	// gen 4 (2372.42, 101.088, 120.125)
	teleportPlayer(self, (2372.42, 101.088, 120.125));

	iprintln("Build the maxis drone and finish the EE starting with rain fire");
	
	level waittill( "start_of_round" );

	self leaveAlive(24);
}

takeUpgradedFire() {
	fire = get_staff_info_from_weapon_name("staff_fire_zm");
	fire.charge_trigger notify("trigger", getplayers()[0]);
}

activateGenerators() {

	a_s_generator = getstructarray( "s_generator", "targetname" );

	for (i = 0; i < a_s_generator.size; i++) {
		a_s_generator[i].n_current_progress = 100;
		a_s_generator[i] handle_generator_capture();
	}
}

upgradeWeapon()
{
    baseweapon = get_base_name(self getcurrentweapon());
    weapon = get_upgrade(baseweapon);
    if(IsDefined(weapon))
    {
        self takeweapon(baseweapon);
        self giveweapon(weapon, 0, self get_pack_a_punch_weapon_options(weapon));
        self switchtoweapon(weapon);
        self givemaxammo(weapon);
    }
}

get_upgrade(weapon)
{
    if (IsDefined(level.zombie_weapons[weapon].upgrade_name) && IsDefined(level.zombie_weapons[weapon]))
        return get_upgrade_weapon(weapon, 0);
    else
        return get_upgrade_weapon(weapon, 1);
}

teleportPlayer(player, origin, angles)
{
    player setOrigin(origin);
    player setPlayerAngles(angles);
}

openAllDoors()
{
    setdvar("zombie_unlock_all", 1);
    wait 0.5;
    Triggers = StrTok("zombie_doors|zombie_door|zombie_airlock_buy|zombie_debris|flag_blocker|window_shutter|zombie_trap","|");
    for(i = 0; i < Triggers.size; i++)
    {
        Trigger = GetEntArray(Triggers[i], "targetname");
        for(j = 0; j < Trigger.size; j++)
        {
            Trigger[j] notify("trigger");
        }
    }
    wait .1;
    setdvar("zombie_unlock_all", 0);
}

setRound(round) {	
	self thread leaveAlive(0);
    level.round_number = (round - 1);
	wait 2;
}

leaveAlive(n)
{
	
    zombs=getaiarray("axis");
    level.zombie_total=n;
    if(isDefined(zombs))
    {
        for(i=0;i<zombs.size-n;i++)
        {
            zombs[i] dodamage(zombs[i].health * 5000,(0,0,0),self);
            wait 0.05;
        }
    }
}

add_craftable_cheat( craftable ) //dev call skipped
{

	if ( !isDefined( level.cheat_craftables ) )
	{
		level.cheat_craftables = [];
	}
	_a112 = craftable.a_piecestubs;
	_k112 = getFirstArrayKey( _a112 );
	while ( isDefined( _k112 ) )
	{
		s_piece = _a112[ _k112 ];
		id_string = undefined;
		client_field_val = undefined;
		if ( isDefined( s_piece.client_field_id ) )
		{
			id_string = s_piece.client_field_id;
			client_field_val = id_string;
		}
		else if ( isDefined( s_piece.client_field_state ) )
		{
			id_string = "gem";
			client_field_val = s_piece.client_field_state;
		}
		tokens = strtok( id_string, "_" );
		display_string = "piece";
		_a134 = tokens;
		_k134 = getFirstArrayKey( _a134 );
		while ( isDefined( _k134 ) )
		{
			token = _a134[ _k134 ];
			if ( token != "piece" && token != "staff" && token != "zm" )
			{
				display_string = ( display_string + "_" ) + token;
			}
			_k134 = getNextArrayKey( _a134, _k134 );
		}
		level.cheat_craftables[ "" + client_field_val ] = s_piece;
        s_piece.waste = "waste";
		_k112 = getNextArrayKey( _a112, _k112 );
	}
	flag_wait( "start_zombie_round_logic" );
	_a149 = craftable.a_piecestubs;
	_k149 = getFirstArrayKey( _a149 );
	while ( isDefined( _k149 ) )
	{
		s_piece = _a149[ _k149 ];
		s_piece craftable_waittill_spawned();
        _k149 = getNextArrayKey( _a149, _k149 );
	}
	
}

addCheatCraftables() {
    foreach (s_craftable in level.zombie_include_craftables) {
		level thread add_craftable_cheat( s_craftable );
    }
}

pickupEverything() //checked changed to match cerberus output
{
	keys = getarraykeys( level.cheat_craftables );
	foreach ( key in keys )
	{
		if (!issubstr( key, "shield" )) {
			s_piece = level.cheat_craftables[ key ];
			if ( isDefined( s_piece.piecespawn ) )
			{
				self player_take_piece( s_piece.piecespawn );
			}
		}
	} 
	for ( i = 1; i <= 4; i++ )
	{
		level notify( "player_teleported", a_players[0], i );
		wait_network_frame();
		piece_spawn = level.cheat_craftables[ "" + i ].piecespawn;
		if ( isDefined( piece_spawn ) )
		{
			if ( isDefined( a_players[ i - 1 ] ) )
			{
				a_players[ i - 1 ] maps/mp/zombies/_zm_craftables::player_take_piece( piece_spawn );
				wait_network_frame();
			}
		}
		wait_network_frame();
	}
}

openChamber() {
	level.b_open_all_gramophone_doors = 1;
    trig_position = getstruct( getentarray( "chamber_entrance", "targetname" )[0].targetname + "_position", "targetname" );
    trig_position.trigger notify( "trigger", getplayers()[0] );
}

gramAtWind() {
    wait 15;

    portals = getstructarray( "stargate_gramophone_pos", "targetname" );

    portals[2] activatePortal();
}

activatePortal() {
    t_gramophone = tomb_spawn_trigger_radius( self.origin, 60, 1 );
    self.gramophone_model = spawn( "script_model", self.origin );
	self.gramophone_model.angles = self.angles;
	self.gramophone_model setmodel( "p6_zm_tm_gramophone" );
	level setclientfield( "piece_record_zm_player", 0 );
	flag_set( "gramophone_placed" );
	t_gramophone set_unitrigger_hint_string( "" );
	t_gramophone trigger_off();
	stargate_teleport_enable( self.script_int );
	flag_wait( "teleporter_building_" + self.script_int );
	flag_waitopen( "teleporter_building_" + self.script_int );
	t_gramophone trigger_on();
	t_gramophone set_unitrigger_hint_string( &"ZM_TOMB_PUGR" );
	if ( isDefined( self.script_flag ) )
	{
		flag_set( self.script_flag );
	}
}

progressEE() {
	flag_set( "ee_all_staffs_crafted" );
	flag_set( "ee_all_staffs_upgraded" );

	level waittill( "little_girl_lost_step_1_over" );

	flag_set( "ee_all_staffs_placed" );

	level waittill( "little_girl_lost_step_6_over" );

	_a350 = level.a_elemental_staffs;
	_k350 = getFirstArrayKey( _a350 );
	while ( isDefined( _k350 ) )
	{
		if (!_a350[ _k350 ].weapname == "staff_fire_zm") {
			_a350[ _k350 ].upgrade.charger.is_inserted = 1;
		}
		_k350 = getNextArrayKey( _a350, _k350 );
	}
}

upgradeStaffs() {
	foreach ( staff in level.a_elemental_staffs ) {
		staff thread place_staff_in_charger();
		wait 1;
		staff.charge_trigger notify("trigger", getplayers()[0]);
		flag_set(staff.weapname + "_upgrade_unlocked");
		staff.charger.charges_received = 20;
	}
}

zombie_spawn_delay_fix()
{
	while ( 1 )
	{
		level waittill( "start_of_round" );

		delay = 2;
		for (i = 2; i <= level.round_number; i++) {
			delay *= 0.95;
		}

		level.zombie_vars[ "zombie_spawn_delay" ] = delay;
	}
}
