/// Hand of God - Main defines file
/// Follows the pattern established by code/__DEFINES/vampires.dm

/// Uncomment this to enable testing of Hand of God features
//#define HOG_TESTING

#ifdef HOG_TESTING
#ifdef CIBUILDING
#error HOG_TESTING is enabled, disable this!
#else
#warn HOG_TESTING is enabled, you REALLY do not want this enabled outside of local testing!
#endif
#endif

/**
 * Team defines
 */
#define HOG_TEAM_RED "red"
#define HOG_TEAM_BLUE "blue"

/**
 * Faith defines
 */
/// Starting faith for a new deity
#define HOG_FAITH_STARTING 100
/// Maximum faith a deity can hold
#define HOG_FAITH_MAX 100
/// Faith cost to place a nexus
#define HOG_FAITH_COST_NEXUS 0
/// Faith cost to place a trap
#define HOG_FAITH_COST_TRAP 20
/// Faith cost to start a structure
#define HOG_FAITH_COST_STRUCTURE 75

/**
 * Nexus defines
 */
/// Nexus maximum integrity
#define HOG_NEXUS_MAX_INTEGRITY 500
/// Time before nexus is force-placed
#define HOG_NEXUS_FORCE_TIME (15 MINUTES)

/**
 * Follower defines
 */
/// Followers needed before a prophet can be appointed
#define HOG_FOLLOWERS_FOR_PROPHET 3

/**
 * Antag HUD defines
 */
#define ANTAG_HUD_HOG_RED 36
#define ANTAG_HUD_HOG_BLUE 37

/**
 * HUD screen location defines
 */
#define ui_deityhealth "EAST-1:28,CENTER-2:13"
#define ui_deitypower "EAST-1:28,CENTER-1:15"
#define ui_deityfollowers "EAST-1:28,CENTER:17"

/**
 * Traits
 */
/// Given to cultists to mark them as followers
#define TRAIT_HOG_CULTIST "trait_hog_cultist"
/// Given to prophets
#define TRAIT_HOG_PROPHET "trait_hog_prophet"

/**
 * Trait sources
 */
#define TRAIT_HOG "trait_handofgod"

/**
 * Signals
 */
/// Called when a new follower joins the cult
#define COMSIG_HOG_FOLLOWER_GAINED "comsig_hog_follower_gained"
/// Called when a follower leaves the cult
#define COMSIG_HOG_FOLLOWER_LOST "comsig_hog_follower_lost"
/// Called when a nexus is destroyed
#define COMSIG_HOG_NEXUS_DESTROYED "comsig_hog_nexus_destroyed"
/// Called when a deity dies
#define COMSIG_HOG_DEITY_DEATH "comsig_hog_deity_death"

/**
 * Macros
 */
/// Checks if the given mob is a hand of god deity (camera mob)
#define IS_HOG_GOD(mob) (istype(mob, /mob/camera/god))
