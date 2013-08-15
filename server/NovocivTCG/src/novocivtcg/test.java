package novocivtcg;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLEncoder;

/**
 * test.java Function Date Jul 25, 2013
 *
 * @author Hoten
 */
public class test {

    public static void main(String[] args) throws MalformedURLException, IOException, InterruptedException {
        URL url = new URL("http://forums.novociv.org/card.php?section=app&do=deckarray&foo=bar");
        HttpURLConnection request = (HttpURLConnection) url.openConnection();
        request.setRequestProperty("Content-type", "application/x-www-form-urlencoded");
        request.setRequestMethod("POST");
        request.setDoOutput(true);
        OutputStreamWriter post = new OutputStreamWriter(request.getOutputStream());
        String data = URLEncoder.encode("user_id", "UTF-8") + "=" + URLEncoder.encode("1", "UTF-8");
        post.write(data);
        post.flush();

        BufferedReader in = new BufferedReader(new InputStreamReader(request.getInputStream()));
        String line;
        while ((line = in.readLine()) != null) {
            System.out.println(line);
        }
    }
}
