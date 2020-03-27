/*===================================================

		  @ Filterscript - Dynamic Actors
		  @ Author - Alex
		  @ Date - 27th March
		  @ Copyright (C) 2020

===================================================*/

// > SA-MP stdlib
#include <a_samp>

// > CMD-Process
#include <Pawn.CMD>
#include <sscanf2>

#include <a_mysql>

// > Iterators
#include <YSI_Data\y_iterate>

#define SCM SendClientMessage

// > MySQL

static
	MySQL:dbHandler;

stock const MYSQL_HOST[20] = "localhost";
stock const MYSQL_USER[5] = "root";
stock const MYSQL_DB[20] = "dyn_actors";

// > Actors

#define TABLE_ACTORS 	"actors"
const _MAX_ACTORS = 	(50);

enum E_ACTOR_DATA
{
	@actorid,
	@actorskin,
	Float:@aX,
	Float:@aY,
	Float:@aZ,
	Float:@aA
}

static
	E_ACTOR_INFO[_MAX_ACTORS char][E_ACTOR_DATA],
	ACTOR_MODEL[_MAX_ACTORS char],
	Iterator:Iter_Actors<_MAX_ACTORS char>;

// > Aliases

alias:createactor("ca");
alias:gotoactor("ga");
alias:locateactor("la");

// > Script init

main() {}

public OnGameModeInit()
{
	new
		MySQLOpt: option_id = mysql_init_options();
  
    dbHandler = mysql_connect(MYSQL_HOST, MYSQL_USER, "", MYSQL_DB, option_id);
  
    if (dbHandler == MYSQL_INVALID_HANDLE || mysql_errno(dbHandler) != 0)
    {
        SendRconCommand("exit");
        return 1;
    }
    
    printf(
    	"[MySQL]: Connection successfully - [%s/%s/%s]",
    	MYSQL_HOST, MYSQL_USER, MYSQL_DB
    );

    mysql_tquery(dbHandler, "SELECT * FROM `"TABLE_ACTORS"`", "SQL_LOAD_ACTORS_FROM_DB", "");
	return 1;
}


// > Loading actors from database

forward SQL_LOAD_ACTORS_FROM_DB();
public SQL_LOAD_ACTORS_FROM_DB()
{
	if (cache_num_rows())
	{
		for (new i; i < cache_num_rows(); ++i)
		{
			new
				id = Iter_Free(Iter_Actors);

			cache_get_value_name_int(i, "ActorID", E_ACTOR_INFO[id][@actorid]);
			cache_get_value_name_int(i, "ActorSkin", E_ACTOR_INFO[id][@actorskin]);

			cache_get_value_name_float(i, "ActorX", E_ACTOR_INFO[id][@aX]);
			cache_get_value_name_float(i, "ActorY", E_ACTOR_INFO[id][@aY]);
			cache_get_value_name_float(i, "ActorZ", E_ACTOR_INFO[id][@aZ]);
			cache_get_value_name_float(i, "ActorA", E_ACTOR_INFO[id][@aA]);

			ACTOR_MODEL[id] = CreateActor(
					E_ACTOR_INFO[id][@actorskin],
					E_ACTOR_INFO[id][@aX],
					E_ACTOR_INFO[id][@aY],
					E_ACTOR_INFO[id][@aZ],
					E_ACTOR_INFO[id][@aA]
			);

			Iter_Add(Iter_Actors, id);
		}
	}
	return 1;
}

// > Function
forward INSERT_ACTOR_ID_INTO_DB(_actorid);
public INSERT_ACTOR_ID_INTO_DB(_actorid)
{
	E_ACTOR_INFO[_actorid][@actorid] = cache_insert_id();
	Iter_Add(Iter_Actors, _actorid);
	return 1;
}

// > Commands
CMD:createactor(playerid, const params[])
{
	if (!IsPlayerAdmin(playerid))
		return SCM(playerid, 0xFF0000AA, "Error > Morate se ulogovati na rcon.");

	new
		actor_id,
		i = Iter_Free(Iter_Actors),
		query[240],

		// > Player coordinates
		Float:x,
		Float:y,
		Float:z,
		Float:a;

	if (sscanf(params, "i", actor_id))
		return SCM(playerid, 0xE2E2E2FF, "Usage > /createactor [skin id]");

	if (actor_id < 1 || actor_id > 311)
		return SCM(playerid, 0xFF0000AA, "Error > Invalid skin id!");

	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, a);

	E_ACTOR_INFO[i][@aX] = x,
	E_ACTOR_INFO[i][@aY] = y,
	E_ACTOR_INFO[i][@aZ] = z,
	E_ACTOR_INFO[i][@aA] = a;
	
	E_ACTOR_INFO[i][@actorskin] = actor_id;

	mysql_format(dbHandler, query, sizeof query, "\
		INSERT INTO `"TABLE_ACTORS"` (`ActorSkin`, `ActorX`, `ActorY`, `ActorZ`, `ActorA`) \
		VALUES ('%d', '%f', '%f', '%f', '%f')", actor_id, x, y, z, a);
	mysql_tquery(dbHandler, query, "INSERT_ACTOR_ID_INTO_DB", "i", i);

	ACTOR_MODEL[i] = CreateActor(actor_id, x, y, z, a);

	SetPlayerPos(playerid, (x+1), y, z);
	return 1;
}

CMD:gotoactor(playerid, const params[])
{
	new id;

	if (sscanf(params, "i", id))
		return SCM(playerid, 0xE2E2E2FF, "Usage > /gotoactor [actor id]");

	if (!Iter_Contains(Iter_Actors, id))
		return SCM(playerid, 0xFF0000AA, "Error > Invalid actor ID!");

	GetActorPos(ACTOR_MODEL[id], E_ACTOR_INFO[id][@aX], E_ACTOR_INFO[id][@aY], E_ACTOR_INFO[id][@aZ]);
	
	SetPlayerPos(playerid, (E_ACTOR_INFO[id][@aX]+1), E_ACTOR_INFO[id][@aY], E_ACTOR_INFO[id][@aZ]);
	return 1;
}

CMD:locateactor(playerid, const params[])
{
	new id;

	if (sscanf(params, "i", id))
		return SCM(playerid, 0xE2E2E2FF, "Usage > /locateactor [actor id]");

	if (!Iter_Contains(Iter_Actors, id))
		return SCM(playerid, 0xFF0000AA, "Error > Invalid actor ID!");

	GetActorPos(ACTOR_MODEL[id], E_ACTOR_INFO[id][@aX], E_ACTOR_INFO[id][@aY], E_ACTOR_INFO[id][@aZ]);
	
	SetPlayerCheckpoint(playerid, (E_ACTOR_INFO[id][@aX]+1), E_ACTOR_INFO[id][@aY], E_ACTOR_INFO[id][@aZ], 3.0);
	return 1;
}
