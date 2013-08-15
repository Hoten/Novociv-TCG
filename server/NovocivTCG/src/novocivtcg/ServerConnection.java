package novocivtcg;

/**
 * ServerConnection.java
 *
 * Collection of message types for sending data to the client.
 *
 * @author Hoten
 */
public class ServerConnection {

    final public static int PLAY_SHUFFLE_SFX = 2;
    final public static int CHAT = 3;
    final public static int ALERT_NEW_USER = 4;
    final public static int CURRENT_USERS = 5;
    final public static int REQUEST_GAME = 6;
    final public static int GAME_REQUEST_RESPONSE = 7;
    final public static int DECKS_LIST = 8;
    final public static int BEGIN_GAME = 9;
    final public static int HEARTBEAT = 10;
    final public static int ADD_TO_HAND = 11;
    final public static int PLAY_CARD = 12;
    final public static int MOVE_CARD = 13;
    final public static int OPPONENT_HAND_CHANGE = 14;
    final public static int TAP_CARD = 15;
    final public static int UPDATE_DECKSIZES = 16;
    final public static int REMOVE_FROM_FIELD = 17;
    final public static int UPDATE_LIFE = 18;
    final public static int DRAW_ARROW = 19;
    final public static int REMOVE_FROM_LOBBY = 20;
    final public static int NEW_COUNTER = 21;
    final public static int SET_COUNTER = 22;
    final public static int MOVE_COUNTER = 23;
    final public static int BEGIN_DECK_SEARCH = 24;
    final public static int DELETE_COUNTER = 25;
}
