package novocivtcg;

import hoten.serving.ByteArray;
import hoten.serving.SocketHandler;
import java.io.IOException;
import java.net.Socket;

/**
 * ClientConnection.java
 *
 * Handles messages from a client.
 *
 * @author Hoten
 */
public class ClientConnection extends SocketHandler {

    final private TCGServingSocket server;
    protected Profile profile;

    public ClientConnection(TCGServingSocket server, Socket socket) throws IOException {
        super(socket);
        this.server = server;
        profile = new Profile();
        send(server.createCurrentUsersInLobbyMessage());
    }

    @Override
    protected void handleData(ByteArray reader) throws IOException {
        ByteArray msg;
        int type = reader.getType();
        switch (type) {
            case 17:
                if (profile == null) {
                    close();
                    return;
                }
                profile.username = reader.readUTF();
                profile.userid = reader.readInt();
                System.out.println(profile.username + " - " + profile.userid);
                if (profile.username.equals("Unregistered")) {
                    close();
                } else {
                    msg = new ByteArray();
                    msg.setType(ServerConnection.ALERT_NEW_USER);
                    msg.writeUTF(profile.username);
                    server.sendToAllNotInGameBut(msg, this);
                    msg = Driver.createAvailableDecksMessage(profile.userid);
                    if (msg == null) {
                        close();
                    } else {
                        send(msg);
                    }
                }
                break;
            case 1:
                //removed
                break;
            case 2:
                msg = new ByteArray();
                msg.setType(ServerConnection.CHAT);
                msg.writeUTF(profile.username + ": " + reader.readUTF());
                if (profile.currentGame == null) {
                    server.sendToAllNotInGame(msg);
                } else {
                    profile.currentGame.player1.send(msg);
                    profile.currentGame.player2.send(msg);
                }
                break;
            case 3:
                String un = reader.readUTF();
                ClientConnection opponent = server.searchByName(un);
                if (opponent != null) {
                    GameInstance game = Driver.createNewGame();
                    game.player1 = this;
                    game.player2 = opponent;
                    msg = new ByteArray();
                    msg.setType(ServerConnection.REQUEST_GAME);
                    msg.writeUTF(profile.username);
                    msg.writeInt(game.id);
                    opponent.send(msg);
                    msg = new ByteArray();
                    msg.setType(ServerConnection.REMOVE_FROM_LOBBY);
                    msg.writeUTF(profile.username);
                    server.sendToAllNotInGame(msg);
                } else {
                    msg = new ByteArray();
                    msg.setType(ServerConnection.CHAT);
                    msg.writeUTF("that user cannot be found");
                    server.sendToAll(msg);
                }
                break;
            case 4:
                //client's response to a game request
                int gameid = reader.readInt();
                GameInstance game = Driver.games.get(gameid);
                boolean accepted = reader.readBoolean();
                if (accepted) {
                    game.hasPlayer2Joined = true;
                    profile.currentGame = game;
                    game.player1.profile.currentGame = game;
                    msg = new ByteArray();
                    msg.setType(ServerConnection.REMOVE_FROM_LOBBY);
                    msg.writeUTF(profile.username);
                    server.sendToAllNotInGame(msg);
                } else {
                    Driver.games.remove(gameid);
                    msg = new ByteArray();
                    msg.setType(ServerConnection.ALERT_NEW_USER);
                    msg.writeUTF(profile.username);
                    server.sendToAllBut(msg, this);
                }
                msg = new ByteArray();
                msg.setType(ServerConnection.GAME_REQUEST_RESPONSE);
                msg.writeBoolean(accepted);
                game.player1.send(msg);
                break;
            case 5:
                //deck selection
                int deckid = reader.readInt();
                profile.currentGame.setDeck(Driver.loadDeck(deckid), this);
                break;
            case 6:
                //draw
                profile.currentGame.draw(this);
                break;
            case 7:
                //play card
                profile.currentGame.playCard(this, reader.readInt());
                break;
            case 8:
                //move card
                profile.currentGame.moveCard(this, reader.readShort(), reader.readShort(), reader.readShort());
                break;
            case 9:
                //tap card
                profile.currentGame.tapCard(reader.readInt());
                break;
            case 10:
                //place on deck
                profile.currentGame.putBackInDeck(this, reader.readShort());
                break;
            case 11:
                //shuffle
                profile.currentGame.shuffle(this);
                break;
            case 12:
                //field to hand
                profile.currentGame.fieldToHand(this, reader.readShort());
                break;
            case 13:
                //draw arrow
                profile.currentGame.drawArrow(reader.readShort(), reader.readShort(), reader.readShort(), reader.readShort());
                break;
            case 14:
                //create counter
                profile.currentGame.createCounter(reader.readShort(), reader.readShort());
                break;
            case 15:
                //change counter
                profile.currentGame.setCounter(reader.readShort(), reader.readShort());
                break;
            case 16:
                //move counter
                profile.currentGame.moveCounter(reader.readShort(), reader.readShort(), reader.readShort());
                break;
            case 18:
                //search deck
                profile.currentGame.sendPlayerDeckToSearch(this);
                break;
            case 19:
                //DEPRECATED
                break;
            case 20:
                //client closed deck view
                profile.currentGame.sendChatMessage(profile.username + " is done looking through the deck.");
                profile.currentGame.shuffle(this);
                break;
            case 21:
                //move card from hand to on top of deck
                profile.currentGame.handToDeck(this, reader.readShort());
                break;
            case 22:
                //select from deck to field
                profile.currentGame.deckToField(this, reader.readShort());
                break;
            case 23:
                //select from deck to hand
                profile.currentGame.deckToHand(this, reader.readShort());
                break;
            case 24:
                //delete counter
                profile.currentGame.deleteCounter(reader.readShort());
                break;
        }
    }

    public void logout() {
        if (profile != null) {
            ByteArray msg = new ByteArray();
            msg.setType(ServerConnection.REMOVE_FROM_LOBBY);
            msg.writeUTF(profile.username);
            server.sendToAllBut(msg, this);
            if (profile.currentGame != null) {
                profile.currentGame.sendChatMessage(profile.username + " has left.");
            }
            profile = null;
        }
    }

    @Override
    public void close() {
        if (isOpen()) {
            super.close();
            server.removeClient(this);
            logout();
        }
    }
}
