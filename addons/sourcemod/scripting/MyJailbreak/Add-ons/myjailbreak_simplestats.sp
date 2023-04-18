/*
 * MyJailbreak - Ratio - Simple Stats Support.
 * by: shanapu
 * https://github.com/shanapu/MyJailbreak/
 * 
 * Copyright (C) 2016-2017 Thomas Schmidt (shanapu)
 *
 * This file is part of the MyJailbreak SourceMod Plugin.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

/******************************************************************************
                   STARTUP
******************************************************************************/


// Includes
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colors>
#include <autoexecconfig>
#include <mystocks>
#include <SimpleStats>
#include <myjailbreak>


// Compiler Options
#pragma semicolon 1
#pragma newdecls required


// Console Variables
ConVar gc_iMinTimeRatio;
ConVar gc_iMinTimeWarden;

char g_sPrefixW[64];
char g_sPrefixR[64];


// Info
public Plugin myinfo = {
	name = "MyJailbreak - SimpleStats Support for Ratio & Warden", 
	author = "shanapu, Addicted, good_live", 
	description = "Adds support for nhnkl159 SimpleStats plugin to MyJB ratio & warden", 
	version = MYJB_VERSION, 
	url = MYJB_URL_LINK
};


// Start
public void OnPluginStart()
{
	// Translation
	LoadTranslations("MyJailbreak.Ratio.phrases");
	LoadTranslations("MyJailbreak.Warden.phrases");

	// AutoExecConfig
	AutoExecConfig_SetFile("Ratio", "MyJailbreak");
	AutoExecConfig_SetCreateFile(true);

	gc_iMinTimeRatio = AutoExecConfig_CreateConVar("sm_ratio_simplestats", "0", "0 - disabled, how many seconds a player need to join ct? (only if SimpleStats is available)", _, true, 0.0);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	// AutoExecConfig
	AutoExecConfig_SetFile("Warden", "MyJailbreak");
	AutoExecConfig_SetCreateFile(true);

	gc_iMinTimeWarden = AutoExecConfig_CreateConVar("sm_warden_simplestats", "0", "0 - disabled, how many seconds a player need to become warden? (only if SimpleStats is available)", _, true, 0.0);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	// Hooks
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
}


public void OnAllPluginsLoaded()
{
	if (!LibraryExists("myratio") && !LibraryExists("warden"))
	{
		SetFailState("MyJailbreaks Ratio (ratio.smx) and Warden (warden.smx) plugins are missing. You need at least one of them.");
	}
}

public void OnConfigsExecuted()
{
	ConVar cBuffer = FindConVar("sm_ratio_prefix");
	cBuffer.GetString(g_sPrefixR, sizeof(g_sPrefixR));

	cBuffer = FindConVar("sm_warden_prefix");
	cBuffer.GetString(g_sPrefixW, sizeof(g_sPrefixW));
}


public Action MyJailbreak_OnJoinGuardQueue(int client)
{
	if (SS_GetPlayTimeAmount(client) < gc_iMinTimeRatio.IntValue)
	{
		char buffer[124];
		SecondsToString(gc_iMinTimeRatio.IntValue, buffer, sizeof(buffer), client);
		
		CPrintToChat(client, "%s %t", g_sPrefixR, "ratio_simplestats", buffer);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}


public Action warden_OnWardenCreate(int client, int caller)
{
	if (SS_GetPlayTimeAmount(client) < gc_iMinTimeWarden.IntValue)
	{
		char buffer[124];
		SecondsToString(gc_iMinTimeWarden.IntValue, buffer, sizeof(buffer), client);
		
		CPrintToChat(client, "%s %t", g_sPrefixW, "warden_simplestats", buffer);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}


public Action Event_OnPlayerSpawn(Event event, const char[] name, bool bDontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (!IsValidClient(client, false, false))
		return Plugin_Continue;

	if (GetClientTeam(client) != CS_TEAM_CT)
		return Plugin_Continue;

	if (MyJailbreak_IsEventDayRunning())
		return Plugin_Continue;

	if (SS_GetPlayTimeAmount(client) < gc_iMinTimeRatio.IntValue)
	{
		char buffer[124];
		SecondsToString(gc_iMinTimeRatio.IntValue, buffer, sizeof(buffer), client);
		
		CPrintToChat(client, "%s %t", g_sPrefixR, "ratio_simplestats", buffer);
		CreateTimer(5.0, Timer_SlayPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Continue;
	}

	return Plugin_Continue;
}


public Action Timer_SlayPlayer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);

	if ((IsValidClient(client, false, false)) && (GetClientTeam(client) == CS_TEAM_CT))
	{
		ForcePlayerSuicide(client);
		ChangeClientTeam(client, CS_TEAM_T);
		CS_RespawnPlayer(client);
		MinusDeath(client);
	}

	return Plugin_Stop;
}


void MinusDeath(int client)
{
	if (IsValidClient(client, true, true))
	{
		int frags = GetEntProp(client, Prop_Data, "m_iFrags");
		int deaths = GetEntProp(client, Prop_Data, "m_iDeaths");
		SetEntProp(client, Prop_Data, "m_iFrags", (frags+1));
		SetEntProp(client, Prop_Data, "m_iDeaths", (deaths-1));
	}
}


// function by Franc1sco's simplestats
int SecondsToString(int Time, char[] buffer, int buffersize, int client)
{
	int iHours = 0;
	int iMinutes = 0;
	int iSeconds = Time;
	
	while(iSeconds > 3600)
	{
		iHours++;
		iSeconds -= 3600;
	}
	while(iSeconds > 60)
	{
		iMinutes++;
		iSeconds -= 60;
	}
	if (iHours >= 1)
	{
		Format(buffer, buffersize, "%d %t", iHours, "ratio_hours", client);
		Format(buffer, buffersize, "%s %d %t", buffer, iMinutes, "ratio_minutes", client);
		Format(buffer, buffersize, "%s %d %t", buffer, iSeconds, "ratio_seconds", client);
	}
	else if (iMinutes >= 1)
	{
		Format(buffer, buffersize, "%d %t", iMinutes, "ratio_minutes", client);
		Format(buffer, buffersize, "%s %d %t", buffer, iSeconds, "ratio_seconds", client);
	}
	else
	{
		Format(buffer, buffersize, "%d %t", iSeconds, "ratio_seconds", client);
	}
}