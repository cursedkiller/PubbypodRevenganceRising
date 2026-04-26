/// Hand of God - Main defines file

/// Uncomment this to enable testing of Hand of God features
//#define HOG_TESTING

#ifdef HOG_TESTING
#ifdef CIBUILDING
#error HOG_TESTING is enabled, disable this!
#else
#warn HOG_TESTING is enabled, you REALLY do not want this enabled outside of local testing!
#endif
#endif

#define HOG_TEAM_RED "red"
#define HOG_TEAM_BLUE "blue"
#define HOG_FAITH_STARTING 100
#define HOG_FAITH_MAX 100
#define HOG_FAITH_COST_NEXUS 0
#define HOG_FAITH_COST_TRAP 20
#define HOG_FAITH_COST_STRUCTURE 75
#define HOG_NEXUS_MAX_INTEGRITY 500
#define HOG_NEXUS_FORCE_TIME (15 MINUTES)
#define HOG_FOLLOWERS_FOR_PROPHET 3
#define ANTAG_HUD_HOG_RED 36
#define ANTAG_HUD_HOG_BLUE 37
#define ui_deityhealth "EAST-1:28,CENTER-2:13"
#define ui_deitypower "EAST-1:28,CENTER-1:15"
#define ui_deityfollowers "EAST-1:28,CENTER:17"
#define FACTION_RED_GOD "red god"
#define FACTION_BLUE_GOD "blue god"
#define TRAIT_HOG_CULTIST "trait_hog_cultist"
#define TRAIT_HOG_PROPHET "trait_hog_prophet"
#define TRAIT_HOG "trait_handofgod"
#define COMSIG_HOG_FOLLOWER_GAINED "comsig_hog_follower_gained"
#define COMSIG_HOG_FOLLOWER_LOST "comsig_hog_follower_lost"
#define COMSIG_HOG_NEXUS_DESTROYED "comsig_hog_nexus_destroyed"
#define COMSIG_HOG_DEITY_DEATH "comsig_hog_deity_death"
#define IS_HOG_GOD(M) (istype(M, /mob/living/simple_animal/god))
