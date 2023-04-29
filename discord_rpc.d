module discord_rpc;

extern (C) {

struct DiscordRichPresence {
	char *state;   /* max 128 bytes */
	char *details; /* max 128 bytes */
	long startTimestamp;
	long endTimestamp;
	char *largeImageKey;  /* max 32 bytes */
	char *largeImageText; /* max 128 bytes */
	char *smallImageKey;  /* max 32 bytes */
	char *smallImageText; /* max 128 bytes */
	char *partyId;        /* max 128 bytes */
	int partySize;
	int partyMax;
	char *matchSecret;    /* max 128 bytes */
	char *joinSecret;     /* max 128 bytes */
	char *spectateSecret; /* max 128 bytes */
	byte instance;
}
struct DiscordEventHandlers {
	void function(const DiscordUser *request) ready;
	void function(int errorCode, const char *message) disconnected;
	void function(int errorCode, const char *message) errored;
	void function(const char *joinSecret) joinGame;
	void function(const char *spectateSecret) spectateGame;
	void function(const DiscordUser *request) joinRequest;
}
struct DiscordUser {
	char *userId;
	char *username;
	char *discriminator;
	char *avatar;
}

enum {
	DISCORD_REPLY_NO     = 0,
	DISCORD_REPLY_YES    = 1,
	DISCORD_REPLY_IGNORE = 2
}

void Discord_Initialize(const char *applicationId, DiscordEventHandlers *handlers, int autoRegister, const char *optionalSteamId) nothrow @nogc @system;
void Discord_Shutdown() nothrow @nogc @system;
void Discord_RunCallbacks() nothrow @nogc @system;
void Discord_UpdateConnection() nothrow @nogc @system;
void Discord_UpdatePresence(const DiscordRichPresence *presence) nothrow @nogc @system;
void Discord_ClearPresence() nothrow @nogc @system;
void Discord_Respond(const char *userid, int reply) nothrow @nogc @system;
void Discord_UpdateHandlers(DiscordEventHandlers *handlers) nothrow @nogc @system;

}
