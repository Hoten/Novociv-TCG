package novocivtcg;

import hoten.serving.ByteArray;
import hoten.serving.FlashPolicySocket;
import java.io.BufferedReader;
import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Driver.java
 *
 * Entry point.
 *
 * @author Hoten
 */
public class Driver {

    public static TCGServingSocket server;
    public static FlashPolicySocket policySocket;
    public static HashMap<Integer, GameInstance> games = new HashMap();

    public static void main(String[] args) throws IOException {
        String clientdatafolder = args.length == 0 ? "clientdata" : args[0];

        policySocket = new FlashPolicySocket();
        server = new TCGServingSocket(8200);

        policySocket.start();
        server.start();

        System.out.println("Server started.");
    }

    public static String encrypt(byte[] bytes) {
        MessageDigest algorithm;
        try {
            algorithm = MessageDigest.getInstance("MD5");
        } catch (NoSuchAlgorithmException ex) {
            Logger.getLogger(Driver.class.getName()).log(Level.SEVERE, null, ex);
            return null;
        }
        algorithm.reset();
        algorithm.update(bytes);
        byte[] messageDigest = algorithm.digest();
        StringBuffer hash = new StringBuffer();
        for (int i = 0; i < messageDigest.length; i++) {
            int num = 0xFF & messageDigest[i];
            String append = Integer.toHexString(num);
            if (append.length() == 1) {
                append = "0" + append;
            }
            hash.append(append);
        }
        return hash + "";
    }

    public static byte[] readBytesFromFile(File file) throws FileNotFoundException, IOException {
        byte[] fileData = new byte[(int) file.length()];
        DataInputStream dis = new DataInputStream(new FileInputStream(file));
        dis.readFully(fileData);
        dis.close();
        return fileData;
    }
    static int nextGameId;

    public static GameInstance createNewGame() {
        GameInstance game = new GameInstance(nextGameId++);
        games.put(game.id, game);
        return game;
    }

    public static ByteArray createAvailableDecksMessage(int userid) throws IOException {
        ByteArray msg = new ByteArray();
        msg.setType(ServerConnection.DECKS_LIST);

        String phpresult = loadDeckChoices(userid);
        if (phpresult.length() == 0) {
            return null;
        }

        String[] data = phpresult.split(",");
        try {
            for (int i = 0; i < data.length; i += 2) {
                int deckid = Integer.parseInt(data[i]);
                String deckname = data[i + 1];
                msg.writeInt(deckid);
                msg.writeUTF(deckname);
            }
        } catch (NumberFormatException e) {
            System.out.println(e);
            return null;
        }

        return msg;
    }

    public static Deck loadDeck(int deckid) throws IOException {
        String[] data = queryPhp("http://forums.novociv.org/card.php?section=app&do=cardarray&foo=bar", "deckid", Integer.toString(deckid)).split(",");

        Deck deck = new Deck();
        for (int i = 0; i < data.length; i += 2) {
            String name = data[i].substring(1);
            boolean foil = "1".equals(data[i + 1]);
            deck.addCard(new Card(name, foil));
        }

        return deck;
    }

    public static String loadDeckChoices(int userid) throws IOException {
        String data = queryPhp("http://forums.novociv.org/card.php?section=app&do=deckarray&foo=bar", "user_id", Integer.toString(userid));
        return data;
    }

    private static String queryPhp(String urlString, String postVarName, String postVarValue) throws IOException {
        URL url = new URL(urlString);
        HttpURLConnection request = (HttpURLConnection) url.openConnection();
        request.setRequestProperty("Content-type", "application/x-www-form-urlencoded");
        request.setRequestMethod("POST");
        request.setDoOutput(true);
        OutputStreamWriter post = new OutputStreamWriter(request.getOutputStream());
        String data = URLEncoder.encode(postVarName, "UTF-8") + "=" + URLEncoder.encode(postVarValue, "UTF-8");
        post.write(data);
        post.flush();

        BufferedReader in = new BufferedReader(new InputStreamReader(request.getInputStream()));
        String line;
        StringBuilder builder = new StringBuilder();
        while ((line = in.readLine()) != null) {
            builder.append(line);
        }
        return builder.toString();
    }
}
