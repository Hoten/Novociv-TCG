package novocivtcg;

/**
 * Card.java
 *
 * Card object. name is the relative filename corresponding to the image, and
 * realName is the name of the card.
 *
 * @author Hoten
 */
public class Card {

    final public String name;
    final public String realName;
    final public boolean foil;
    public int x, y;
    public boolean tapped;

    public Card(String name, boolean foil) {
        this.name = name;
        this.foil = foil;
        String[] split = name.split("/");
        realName = split[split.length - 1].replaceAll(".jpg", "");
    }
}
