package novocivtcg;

import hoten.serving.ByteArray;
import java.util.ArrayList;

/**
 * GameInstance.java
 *
 * Handles all game "logic".
 *
 * @author Hoten
 */
public class GameInstance {

    private static final int CLIENT_WIDTH = 1000;
    private static final int CLIENT_HEIGHT = 800;
    private static final int CARD_WIDTH = (int) (375 * 0.3f);
    private static final int CARD_HEIGHT = (int) (523 * 0.3f);
    private static final int DEFAULT_COUNTER_VALUE = 1;
    private static final int DEFAULT_LIFE = 20;
    public int id;
    public ClientConnection player1, player2;
    public boolean hasPlayer2Joined;
    public Deck deck1, deck2;
    public ArrayList<Card> hand1 = new ArrayList(), hand2 = new ArrayList(), field = new ArrayList();
    public ArrayList<Counter> counters = new ArrayList();

    public GameInstance(int id) {
        this.id = id;
    }

    public void tapCard(int index) {
        if (field.size() <= index) {
            return;
        }
        Card c = field.get(index);
        c.tapped = !c.tapped;
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.TAP_CARD);
        msg.writeInt(index);
        msg.writeBoolean(c.tapped);
        sendToBoth(msg);
    }

    public void moveCard(ClientConnection player, int index, int x, int y) {
        if (field.size() <= index) {
            return;
        }
        Card c = field.get(index);
        c.x = x;
        c.y = y;
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.MOVE_CARD);
        msg.writeShort(index);
        msg.writeShort(c.x);
        msg.writeShort(c.y);
        if (player == player1) {
            player2.send(msg);
        } else {
            player1.send(msg);
        }
    }

    public void playCard(ClientConnection player, int index) {
        ArrayList<Card> hand = player == player1 ? hand1 : hand2;
        if (index >= hand.size()) {
            return;
        }
        Card c = hand.remove(index);
        int handsize = hand.size();
        addToField(c);

        updateOpponentHandSize(player);
    }

    public void updateDeckSizes() {
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.UPDATE_DECKSIZES);
        msg.writeByte(deck1.size());
        msg.writeByte(deck2.size());
        sendToBoth(msg);
    }

    private void addToField(Card c) {
        field.add(c);
        c.tapped = false;
        c.x = CLIENT_WIDTH / 2 - CARD_WIDTH / 2;
        c.y = CLIENT_HEIGHT / 2 - CARD_HEIGHT / 2;

        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.PLAY_CARD);
        msg.writeUTF(c.name);
        msg.writeBoolean(c.foil);
        msg.writeInt(c.x);
        msg.writeInt(c.y);

        sendToBoth(msg);
    }

    private void sendToBoth(ByteArray msg) {
        player1.send(msg);
        player2.send(msg);
    }

    public void draw(ClientConnection player) {
        Card c = null;
        if (player == player1) {
            c = deck1.pop();
        } else if (player == player2) {
            c = deck2.pop();
        }
        if (c == null) {
            return;
        }
        if (player == player1) {
            hand1.add(c);
        } else {
            hand2.add(c);
        }
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.ADD_TO_HAND);
        msg.writeUTF(c.name);
        msg.writeBoolean(c.foil);
        player.send(msg);

        updateOpponentHandSize(player);

        updateDeckSizes();
        sendChatMessage(player.profile.username + " drew a card.");
    }

    public void setDeck(Deck deck, ClientConnection player) {
        if (player == player1) {
            deck1 = deck;
        } else if (player == player2) {
            deck2 = deck;
        }

        if (deck1 != null && deck2 != null) {
            begin();
        }
    }

    private void begin() {
        deck1.shuffle();
        deck2.shuffle();
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.BEGIN_GAME);
        msg.writeBoolean(true);
        player1.send(msg);

        msg = new ByteArray();
        msg.setType(ServerConnection.BEGIN_GAME);
        msg.writeBoolean(false);
        player2.send(msg);

        //player 1 life counter
        createCounter(0, 0, DEFAULT_LIFE);
        //player 2 life counter
        createCounter(0, 0, DEFAULT_LIFE);

        msg = new ByteArray();
        msg.setType(ServerConnection.ALERT_NEW_USER);
        msg.writeUTF(player1.profile.username);
        player2.send(msg);
        msg = new ByteArray();
        msg.setType(ServerConnection.ALERT_NEW_USER);
        msg.writeUTF(player2.profile.username);
        player1.send(msg);
    }

    public void putBackInDeck(ClientConnection player, int index) {
        Card card = removeFromField(index);
        if (player == player1) {
            deck1.addCard(card);
        } else {
            deck2.addCard(card);
        }
        sendChatMessage(player.profile.username + " moved " + card.realName + " from Field -> Top of Deck.");
        updateDeckSizes();
    }

    public Card removeFromField(int index) {
        if (index >= field.size() || index < 0) {
            return null;
        }
        Card c = field.remove(index);
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.REMOVE_FROM_FIELD);
        msg.writeShort(index);
        sendToBoth(msg);
        return c;
    }

    public void sendChatMessage(String message) {
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.CHAT);
        msg.writeUTF(message);
        sendToBoth(msg);
    }

    public void shuffle(ClientConnection player) {
        if (player == player1) {
            deck1.shuffle();
        } else {
            deck2.shuffle();
        }
        sendChatMessage(player.profile.username + "'s deck was shuffled.");
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.PLAY_SHUFFLE_SFX);
        sendToBoth(msg);
    }

    public void setLife(boolean player1, int value) {
        if (player1) {
            setCounter(0, value);
        } else {
            setCounter(1, value);
        }
    }

    public void drawArrow(int x0, int y0, int x1, int y1) {
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.DRAW_ARROW);
        msg.writeShort(x0);
        msg.writeShort(y0);
        msg.writeShort(x1);
        msg.writeShort(y1);
        sendToBoth(msg);
    }

    void createCounter(int x, int y) {
        createCounter(x, y, DEFAULT_COUNTER_VALUE);
    }

    void createCounter(int x, int y, int value) {
        counters.add(new Counter(value, x, y));

        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.NEW_COUNTER);
        msg.writeShort(value);
        msg.writeShort(x);
        msg.writeShort(y);
        sendToBoth(msg);
    }

    void setCounter(int index, int value) {
        Counter counter = counters.get(index);
        counter.value = value;

        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.SET_COUNTER);
        msg.writeShort(index);
        msg.writeShort(value);
        sendToBoth(msg);
    }

    void moveCounter(int index, int x, int y) {
        Counter counter = counters.get(index);
        counter.x = x;
        counter.y = y;

        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.MOVE_COUNTER);
        msg.writeShort(index);
        msg.writeShort(x);
        msg.writeShort(y);
        sendToBoth(msg);
    }

    public void sendPlayerDeckToSearch(ClientConnection player) {
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.BEGIN_DECK_SEARCH);

        Deck deck = player == player1 ? deck1 : deck2;
        Card[] cards = deck.copyToArray();
        msg.writeShort(deck.size());
        for (Card c : cards) {
            msg.writeUTF(c.name);
            msg.writeBoolean(c.foil);
        }

        player.send(msg);
        sendChatMessage(player.profile.username + " is looking through the deck...");
    }

    public void handToDeck(ClientConnection player, int index) {
        ArrayList<Card> hand = player == player1 ? hand1 : hand2;
        Deck deck = player == player1 ? deck1 : deck2;
        if (index < hand.size()) {
            Card card = hand.remove(index);
            deck.addCard(card);
            updateDeckSizes();
            updateOpponentHandSize(player);
            sendChatMessage(player.profile.username + " moved a card from Hand -> Top of Deck.");
        }
    }

    public void deckToField(ClientConnection player, int index) {
        Deck deck = player == player1 ? deck1 : deck2;
        if (index < deck.size() && index >= 0) {
            Card card = deck.removeCardAt(index);
            addToField(card);
            updateDeckSizes();
            sendChatMessage(player.profile.username + " moved " + card.realName + " from Deck -> Field.");
        }
    }

    public void deckToHand(ClientConnection player, int index) {
        Deck deck = player == player1 ? deck1 : deck2;
        ArrayList<Card> hand = player == player1 ? hand1 : hand2;
        if (index < deck.size() && index >= 0) {
            Card card = deck.removeCardAt(index);
            hand.add(card);

            ByteArray msg = new ByteArray();
            msg.setType(ServerConnection.ADD_TO_HAND);
            msg.writeUTF(card.name);
            msg.writeBoolean(card.foil);
            player.send(msg);

            updateOpponentHandSize(player);
            updateDeckSizes();
            sendChatMessage(player.profile.username + " moved a card from Deck -> Hand.");
        }
    }

    private void updateOpponentHandSize(ClientConnection player) {
        ArrayList<Card> hand = player == player1 ? hand1 : hand2;
        int handsize = hand.size();
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.OPPONENT_HAND_CHANGE);
        msg.writeByte(handsize);
        if (player == player1) {
            player2.send(msg);
        } else {
            player1.send(msg);
        }
    }

    public void fieldToHand(ClientConnection player, int index) {
        if (index < field.size()) {
            ArrayList<Card> hand = player == player1 ? hand1 : hand2;
            Card card = removeFromField(index);
            hand.add(card);

            ByteArray msg = new ByteArray();
            msg.setType(ServerConnection.ADD_TO_HAND);
            msg.writeUTF(card.name);
            msg.writeBoolean(card.foil);
            player.send(msg);

            updateOpponentHandSize(player);

            sendChatMessage(player.profile.username + " moved " + card.realName + " from Field -> Hand.");
        }
    }

    public void deleteCounter(int index) {
        if (index >= 0 && index < counters.size()) {
            counters.remove(index);
            ByteArray msg = new ByteArray();
            msg.setType(ServerConnection.DELETE_COUNTER);
            msg.writeShort(index);
            sendToBoth(msg);
        }
    }
}
