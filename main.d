import std.conv     : to, ConvException;
import std.datetime : Clock, stdTimeToUnixTime;
import std.file     : exists;
import std.getopt   : getopt, GetOptException, config;
import std.path     : baseName, expandTilde;
import std.process  : environment;
import std.regex    : matchFirst, regex;
import std.stdio    : writeln, writefln, stderr;
import std.string   : toStringz;

import core.stdc.stdlib : exit;
import core.stdc.signal : signal, SIGINT;
import core.stdc.string : memset; import core.runtime     : Runtime;
import core.thread      : dur, Thread;

import discord_rpc;
import dini;

enum VERSION = "0";

enum DEFAULT_CONFIGPATH = "~/.config/discord-rpcli.conf";
enum ENV_CONFIG = "DISCORDRPCLI_CONFIG";

enum DEFAULT_CLIENT = "1098115943542038619";
enum DEFAULT_PRESENCESTATE     = "using discord-rpcli";
enum DEFAULT_PRESENCEDETAILS   = "discord-rpcli example";
enum DEFAULT_PRESENCELIMAGEKEY = "discord-rpcli";

string optClient;
string optState;
string optDetails;
string optLargeImageKey;
string optLargeImageText;
string optSmallImageKey;
string optSmallImageText;
int optPartySize;
int optPartyMax;
long optStartTimestamp;
long optEndTimestamp;
bool optAutomaticStartTimestamp;

bool optVersion;

int main(string[] args)
{
	void msg(string s)
	{
		stderr.writefln("%s: %s", args[0].baseName(), s);
	}

	void panic(string s)
	{
		msg(s);
		scope (exit) {
			Runtime.terminate();
			exit(1);
		}
	}

	// Parse command-line options
	ulong argc = args.length;
	try {
		args.getopt(
			config.bundling,
			config.caseSensitive,
			"b", &optAutomaticStartTimestamp,
			"B", &optStartTimestamp, // 'b' for beginning
			"c", &optClient,
			"d", &optDetails,
			"e", &optEndTimestamp,
			"I", &optLargeImageKey,
			"i", &optSmallImageKey,
			"m", &optPartyMax,
			"p", &optPartySize,
			"s", &optState,
			"T", &optLargeImageText,
			"t", &optSmallImageText,
			"V", &optVersion,
		);
	} catch (GetOptException e) {
		if (!e.msg.matchFirst(regex("^Unrecognized option")).empty)
			panic("unknown option " ~ e.extractOpt());
		else if (!e.msg.matchFirst(regex("^Missing value for argument")).empty)
			panic("missing argument for option " ~ e.extractOpt());
	} catch (ConvException e) {
		if (!e.msg.matchFirst(
		regex("Unexpected '.+' when converting from type string to type (int|long)"))
		.empty) {
			panic("illegal value " ~ e.msg.matchFirst("'.+'")[0] ~ " -- must be integer!");
		}
	}

	bool noOptionsPassed = false;
	if (args.length == argc)
		noOptionsPassed = true;

	if (args.length > 1) {
		stderr.writefln(
			"usage: %s [-B stamp] [-c client] [-d details] [-e stamp] [-Ii image] [-m max] [-p size] [-s state] [-Tt text] [-bV]",
		args[0].baseName());
		return 1;
	}

	if (optVersion) {
		writeln("discord-rpcli version " ~ VERSION);
		return 0;
	}

	// Parse config file
	string configPath = environment.get(ENV_CONFIG, DEFAULT_CONFIGPATH).expandTilde();
	string presenceClient = DEFAULT_CLIENT;
	string presenceState;
	string presenceDetails;
	string presenceLargeImageKey;
	string presenceLargeImageText;
	string presenceSmallImageKey;
	string presenceSmallImageText;
	int presencePartySize;
	int presencePartyMax;
	long presenceStartTimestamp;
	long presenceEndTimestamp;
	if (configPath.exists()) {
		auto iniData = Ini.Parse(configPath);
		T decidePresenceValue(T)(string key, T defaultValue)
		{
			if (iniData["presence"].getKey(key) != "") {
				T ret;
				try
					ret = iniData["presence"].getKey(key).to!T();
				catch (ConvException e)
					panic(configPath ~ ": illegal value for presence." ~ key ~ " -- must be integer!");
				return ret;
			} else
				return defaultValue;
		}
		presenceClient  = decidePresenceValue!string("client",  DEFAULT_CLIENT);
		presenceState   = decidePresenceValue!string("state",   "");
		presenceDetails = decidePresenceValue!string("details", "");
		presenceLargeImageKey  = decidePresenceValue!string("large-image", "");
		presenceLargeImageText = decidePresenceValue!string("large-image-text", "");
		presenceSmallImageKey  = decidePresenceValue!string("small-image", "");
		presenceSmallImageText = decidePresenceValue!string("small-image-text", "");
		presencePartySize      = decidePresenceValue!int("party-size", 0);
		presencePartyMax       = decidePresenceValue!int("party-max", 0);
		presenceStartTimestamp = decidePresenceValue!long("start-timestamp", 0);
		presenceEndTimestamp   = decidePresenceValue!long("end-timestamp", 0);
	}
	if (!noOptionsPassed) {
		// Get presence values from options
		if (optClient)
			presenceClient = optClient;
		if (optState)
			presenceState = optState;
		if (optDetails)
			presenceDetails = optDetails;
		if (optLargeImageKey)
			presenceLargeImageKey = optLargeImageKey;
		if (optLargeImageText)
			presenceLargeImageText = optLargeImageText;
		if (optSmallImageKey)
			presenceSmallImageKey = optSmallImageKey;
		if (optSmallImageText)
			presenceLargeImageText = optSmallImageText;
		if (optPartySize)
			presencePartySize = optPartySize;
		if (optPartyMax)
			presencePartyMax = optPartyMax;
		if (optAutomaticStartTimestamp)
			presenceStartTimestamp = Clock.currStdTime.stdTimeToUnixTime();
		if (optStartTimestamp)
			presenceStartTimestamp = optStartTimestamp;
		if (optEndTimestamp)
			presenceEndTimestamp = optEndTimestamp;
	} else if (!configPath.exists()) {
		// Load defaults
		presenceState   = DEFAULT_PRESENCESTATE;
		presenceDetails = DEFAULT_PRESENCEDETAILS;
		presenceLargeImageKey = DEFAULT_PRESENCELIMAGEKEY;
	}

	// Initialise discord-rpc
	DiscordRichPresence presence;
	memset(&presence, 0, presence.sizeof);
	DiscordEventHandlers handlers;
	memset(&handlers, 0, handlers.sizeof);
	handlers.ready = function void (const DiscordUser *request) @safe
	{
		writeln("discord-rpcli: connected to client");
	};
	handlers.errored = function void (int errorCode, const char* message)
	{
		writeln("discord-rpcli: rpc error " ~ errorCode.to!string() ~ ": " ~ message.to!string());
	};

	Discord_Initialize(presenceClient.toChar(), &handlers, 1, null);

	presence.state          = presenceState.toChar();
	presence.details        = presenceDetails.toChar();
	presence.largeImageKey  = presenceLargeImageKey.toChar();
	presence.largeImageText = presenceLargeImageText.toChar();
	presence.smallImageKey  = presenceSmallImageKey.toChar();
	presence.smallImageText = presenceSmallImageText.toChar();
	presence.partySize      = presencePartySize;
	presence.partyMax       = presencePartyMax;
	presence.startTimestamp = presenceStartTimestamp;
	presence.endTimestamp   = presenceEndTimestamp;

	// Main loop
	while (true) {
		if (presenceStartTimestamp)
			presence.startTimestamp = presenceStartTimestamp - 1;
		Discord_UpdatePresence(&presence);
		Discord_RunCallbacks();
		Thread.sleep(dur!("msecs")(16));
	}

	Discord_Shutdown();

	return 0;
}

string extractOpt(GetOptException e) @safe
{
	return e.msg.matchFirst("-.")[0];
}

char *toChar(const string s) nothrow
{
	return cast(char*)s.toStringz();
}
