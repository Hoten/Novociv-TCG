package novocivtcg;

import java.util.Collections;
import java.util.Stack;

/**
 * Deck.java
 *
 * Stores a list of cards in a stack.
 *
 * @author Hoten
 */
public class Deck {

    public Stack<Card> cards = new Stack();

    public void addCard(Card c) {
        if (c != null) {
            cards.push(c);
        }
    }

    public Card[] copyToArray() {
        return cards.toArray(new Card[cards.size()]);
    }

    public void shuffle() {
        Collections.shuffle(cards);
    }

    public Card pop() {
        if (cards.empty()) {
            return null;
        }
        return cards.pop();
    }

    public int size() {
        return cards.size();
    }

    public Card removeCardAt(int index) {
        return cards.remove(index);
    }
}
