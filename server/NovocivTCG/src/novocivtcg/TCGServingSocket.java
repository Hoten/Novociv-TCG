package novocivtcg;

import hoten.serving.ByteArray;
import hoten.serving.ServingSocket;
import hoten.serving.SocketHandler;
import java.io.IOException;
import java.net.Socket;
import java.util.Iterator;

/**
 * TCGServingSocket.java
 *
 * Socket wrapper.
 *
 * @author Hoten
 */
public class TCGServingSocket extends ServingSocket {

    public TCGServingSocket(int port) throws IOException {
        super(port, 1000);
    }

    public ByteArray createCurrentUsersInLobbyMessage() {
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.CURRENT_USERS);
        for (Iterator<SocketHandler> it = clients.iterator(); it.hasNext();) {
            ClientConnection c = (ClientConnection) it.next();
            if (c.profile != null && c.profile.currentGame == null) {
                msg.writeUTF(c.profile.username);
            }
        }
        return msg;
    }

    public void sendToAllNotInGame(ByteArray bytes) {
        for (Iterator<SocketHandler> it = clients.iterator(); it.hasNext();) {
            ClientConnection c = (ClientConnection) it.next();
            if (c.profile != null && c.profile.currentGame == null) {
                c.send(bytes);
            }
        }
    }

    public void sendToAllNotInGameBut(ByteArray bytes, ClientConnection but) {
        for (Iterator<SocketHandler> it = clients.iterator(); it.hasNext();) {
            ClientConnection c = (ClientConnection) it.next();
            if (c != but && c.profile != null && c.profile.currentGame == null) {
                c.send(bytes);
            }
        }
    }

    public void sendToAllBut(ByteArray bytes, ClientConnection but) {
        for (Iterator<SocketHandler> it = clients.iterator(); it.hasNext();) {
            ClientConnection c = (ClientConnection) it.next();
            if (c != but) {
                c.send(bytes);
            }
        }
    }

    public ClientConnection searchByName(String un) {
        for (Iterator<SocketHandler> it = clients.iterator(); it.hasNext();) {
            ClientConnection c = (ClientConnection) it.next();
            if (c.profile != null && un.equals(c.profile.username)) {
                return c;
            }
        }
        return null;
    }

    @Override
    protected SocketHandler makeNewConnection(Socket newConnection) throws IOException {
        return new ClientConnection(this, newConnection);
    }
}
