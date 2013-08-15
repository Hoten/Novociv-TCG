package  
{
	/**
	 * Main.as
	 * 
	 * Most of the logic for the client resides in this class.
	 * 
	 * @author Hoten
	 */
	
	import fl.controls.List;
	import fl.controls.NumericStepper;
	import fl.controls.TextArea;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Sound;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import hoten.serving.*;

	/**
	 * ...
	 * @author cjc
	 */
	public class Main extends Sprite
	{
		public static const CARD_WIDTH:int = 375;
		public static const CARD_HEIGHT:int = 523;
		public static const CARD_SCALE:Number = 0.35;//scale in hand
		public static const FIELD_SCALE:Number = 0.2;//scale on field
		public static const WHOAMI_URL:String = "http://forums.novociv.org/card.php?section=app&do=name&foo=bar";
		
		private var down:Point = new Point();		
		private var cardFactory:CardFactory;
		private var socket:ServingSocket
		private var deckChooser:List;
		private var field:Array = [];
		private var isPlayer1:Boolean;
		private var challengerGameId:int;
		private var inGame:Boolean = false;
		private var isDragging:Boolean = false;
		private var gameui:GameUI;
		private var un:String;
		private var userid:int;
		private var counters:Array = [];
		private var px:int, py:int;
		private var currentCard:Card;
		private var arrows:Array = [];
		
		private var chat:Chat;
		
		private var handLayout:CardsLayout;
		private var opponentHandLayout:CardsLayout;
		private var searchDeckLayout:CardsLayout;
		
		//sprite containers
		private var arrowContainer:Sprite;
		private var fieldContainer:Sprite;
		private var counterContainer:Sprite;
		
		private var serverIp:String;
		
		public function Main() {
			stage.color = 0;
			serverIp = LoaderInfo(this.root.loaderInfo).parameters.hostip;
			if (serverIp == null) serverIp = "localhost";
			cardFactory = new CardFactory();
			startWhoami();
			initUI();
			stage.addEventListener(KeyboardEvent.KEY_UP, keyUp);
		}
		
		private function toggleFullScreen():void {
			if (stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE) {
				stage.displayState = StageDisplayState.NORMAL;
			}else {
				stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
			}
        }
		
		private function initUI():void {
			deckChooser = new List();
			deckChooser.alpha = 0.8;
			center(deckChooser);
			deckChooser.addEventListener(MouseEvent.DOUBLE_CLICK, function(e:MouseEvent) {
				var deckid:int = deckChooser.selectedItem.data;
				var msg:ServerMessage = new ServerMessage(5);
				msg.writeInt(deckid);
				msg.send();
				openMessage("Waiting on opponent to select deck...");
			});
		}
		
		private function createChatBox():void {
			chat = new Chat();
			
			chat.snd.addEventListener(MouseEvent.CLICK, function (e:MouseEvent) {
				chat.sendMessage();
			});
			chat.ti.addEventListener(KeyboardEvent.KEY_UP, function(e:KeyboardEvent) {
				if (e.keyCode == 13) chat.sendMessage();
			});
			chat.ul.addEventListener(MouseEvent.DOUBLE_CLICK, function(e:MouseEvent) {
				if (!inGame) {
					var un:String = chat.ul.selectedItem.label;
					requestGameWith(un);
					openMessage("Waiting on opponent...");
				}
			});
		}
		
		private function startWhoami():void {
			var whoami:WebpageLoader = new WebpageLoader(WHOAMI_URL, function(data:Object) {
				var split:Array = String(data).split(",");
				un = split[0];
				userid = int(split[1]);
				
				if (serverIp == "localhost") {
					un = "Jared";
					userid = 1;
				}
				
				connectToServer();
			});
			whoami.load();
			openMessage("Determining who you are...");
		}
		
		private function connectToServer():void {
			ServerMessage.socket = socket = new ServingSocket(serverIp, 8200, handleData);
			//socket = new GridiaSocket("64.111.106.205", 8200);
			socket.addEventListener(Event.CONNECT, connectHandler);
			socket.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			socket.addEventListener(Event.CLOSE, closeHandler);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			openMessage("Connecting to " + serverIp + ", please wait...");
		}
		
		private function connectHandler(event:Event):void {
			trace("Connected");
			var msg:ServerMessage = new ServerMessage(17);
			msg.writeUTF(un);
			msg.writeInt(userid);
			msg.send();
			openLobby();
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void {
			openMessage("Connection error\n" + event);
			socket.close();
		}
		
		private function closeHandler(event:Event):void {
			openMessage("Connection lost. Refresh to reconnect, else the server is down. Also, make sure you are logged in to the forums, and have at least one deck!");
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			openMessage("SECURITY ERROR: " + event);
		}
		
		private function keyUp(event:KeyboardEvent):void {
			if (event.keyCode == 192) {
				toggleFullScreen();
			}
		}
		
		private function handleData(bytes:ServerMessage):void {
			bytes.position = 0;
			//trace("msg", bytes.id, bytes.bytesAvailable);
			switch (bytes.id) {
				case 1:
					//removed
					break;
				case 2:
					playShuffleSfx();
					break;
				case 3:
					chat.append(bytes.readUTF());
					break;
				case 4:
					var un:String = bytes.readUTF();
					chat.append(un + " has entered.");
					chat.addToUserList(un);
					break;
				case 5:
					while (bytes.bytesAvailable) {
						chat.addToUserList(bytes.readUTF());
					}
					break;
				case 6:
					openChallenger(bytes.readUTF(), bytes.readInt());
					break;
				case 7:
					if (bytes.readBoolean()) {
						openDeckSelection();
					}else {
						openLobby();
					}
					break;
				case 8:
					var deckdata:Array = [];
					while (bytes.bytesAvailable) {
					    deckdata.push( { data:bytes.readInt(), label:bytes.readUTF() } );
					}
					fillDeckChoicesList(deckdata);
					break;
				case 9:
					isPlayer1 = bytes.readBoolean();
					openGame();
					break;
				case 10:
					//heartbeat
					break;
				case 11:
					addCardToHand(bytes.readUTF(), bytes.readBoolean());
					break;
				case 12:
					//add played card
					addCardToField(bytes.readUTF(), bytes.readBoolean(), bytes.readInt(), bytes.readInt());
					break;
				case 13:
					//move card
					var card:Sprite = field[bytes.readShort()];
					card.x = bytes.readShort();
					card.y = bytes.readShort();
					fieldContainer.setChildIndex(card, fieldContainer.numChildren - 1);
					break;
				case 14:
					setNumOpponentCards(bytes.readByte());
					break;
				case 15:
					//tap card
					setCardTapped(bytes.readInt(), bytes.readBoolean());
					break;
				case 16:
					//update deck size
					var size1:int = bytes.readByte();
					var size2:int = bytes.readByte();
					if (isPlayer1) {
						numInDeck(size1, size2);
					}else {
						numInDeck(size2, size1);
					}
					break;
				case 17:
					//remove from field
					var index:int = bytes.readShort();
					fieldContainer.removeChild(field[index]);
					field.splice(index, 1);
					break;
				case 18:
					//DEPRECATED
					break;
				case 19:
					//draw arrow
					drawArrow(bytes.readShort(), bytes.readShort(), bytes.readShort(), bytes.readShort());
					break;
				case 20:
					chat.removeFromUserList(bytes.readUTF());
					break;
				case 21:
					//new counter
					createCounter(bytes.readShort(), bytes.readShort(), bytes.readShort());
					break;
				case 22:
					//set counter
					setCounter(bytes.readShort(), bytes.readShort());
					break;
				case 23:
					//move counter
					moveCounter(bytes.readShort(), bytes.readShort(), bytes.readShort());
					break;
				case 24:
					//deck to search
					beginSearchingDeck(bytes);
					break;
				case 25:
					//delete counter
					var counterIndex:int = bytes.readShort();
					counters.splice(counterIndex, 1);
					counterContainer.removeChildAt(counterIndex);
					break;
			}
		}
		
		private function fillDeckChoicesList(deckdata:Array):void {
			for each (var o:Object in deckdata) {
				deckChooser.addItem(o);
			}
		}
		
		private function removeAllChildren():void {
			while (numChildren) removeChildAt(0);
			graphics.beginFill(0xFFFFFF);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			graphics.endFill();
		}
		
		private function center(s:DisplayObject):void {
			s.x = stage.stageWidth / 2 - s.width / 2;
			s.y = stage.stageHeight / 2 - s.height / 2;
		}
		
		private function addBg():void {
			[Embed(source = "bg.jpg")]
			var bg:Class;
			var instance = new bg();
			instance.alpha = 0.8;
			addChild(instance);
		}
		
		private function openMessage(txt:String):void {
			removeAllChildren();
			addBg();
			var msg:TextArea = new TextArea();
			msg.width = 500;
			msg.height = 200;
			msg.alpha = 0.8;
			msg.text = txt;
			addChild(msg);
			center(msg);
		}
		
		private function openLobby():void {
			inGame = false;
			removeAllChildren();
			addBg();
			createChatBox();
			addChild(chat);
			chat.arrangeForLobby();
		}
		
		private function openChallenger(un:String, gameid:int):void {
			challengerGameId = gameid;
			removeAllChildren();
			addBg();
			var cc:ChallengerConfirmation = new ChallengerConfirmation();
			addChild(cc);
			center(cc);
			cc.ta.text = "A Challenger approaches! Play against " + un + "?";
			cc.no.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
				openLobby();
				var msg:ServerMessage = new ServerMessage(4);
				msg.writeInt(gameid);
				msg.writeBoolean(false);
				msg.send();
			});
			cc.yes.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
				openDeckSelection();
				var msg:ServerMessage = new ServerMessage(4);
				msg.writeInt(gameid);
				msg.writeBoolean(true);
				msg.send();
			});
		}
		
		private function openDeckSelection():void {
			removeAllChildren();
			addBg();
			addChild(deckChooser);
		}
		
		private function openGame():void {
			inGame = true;
			removeAllChildren();
			
			addBg();
			
			gameui = new GameUI();
			
			addChild(chat);
			chat.arrangeForGame();
			
			var layoutWidth:Number = chat.ta.x - CARD_WIDTH * CARD_SCALE;
			addChild(handLayout = new CardsLayout(layoutWidth, function(card:Card) {
				var index:int = handLayout.remove(card);
				var msg:ServerMessage = new ServerMessage(7);
				msg.writeInt(index);
				msg.send();
			}));
			addChild(opponentHandLayout = new CardsLayout(layoutWidth, function(card:Card) {
				//do nothing
			}));
			addChild(fieldContainer = new Sprite());
			addChild(counterContainer = new Sprite());
			addChild(arrowContainer = new Sprite());
			addChild(searchDeckLayout = new CardsLayout(layoutWidth, function(card:Card) {
				//do nothing
			}, true));
			
			handLayout.y = isPlayer1 ? (stage.stageHeight - CARD_HEIGHT * CARD_SCALE) : 0;
			opponentHandLayout.y = !isPlayer1 ? (stage.stageHeight - CARD_HEIGHT * CARD_SCALE) : 0;
			
			addChild(gameui);
			gameui.draw.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
				if (!isSearchingInDeck) {
					var msg:ServerMessage = new ServerMessage(6);
					msg.send();
				}
			});
			gameui.shuffle.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
				if (!isSearchingInDeck) {
					var msg:ServerMessage = new ServerMessage(11);
					msg.send();
				}
			});
			gameui.search.addEventListener(MouseEvent.CLICK, function(e:MouseEvent) {
				if (isSearchingInDeck) {
					searchDeckLayout.clear();
					fieldContainer.alpha = handLayout.alpha = opponentHandLayout.alpha = 1;
					isSearchingInDeck = false;
					new ServerMessage(20).send();
				}else {
					var msg:ServerMessage = new ServerMessage(18);
					msg.send();
				}
			});
			
			gameui.arrangeFor(isPlayer1);
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
				down = new Point(e.stageX, e.stageY);
			});
			
			stage.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent) {
				if (isDragging) return;
				if (getObjectsUnderPoint(down).length > 2) return;
				var up:Point = new Point(e.stageX, e.stageY);
				var dist:Number = Math.sqrt((down.x - up.x) * (down.x - up.x) + (down.y - up.y) * (down.y - up.y));
				if (dist >= 5) {
					var msg:ServerMessage = new ServerMessage(13);
					msg.writeShort(down.x);
					msg.writeShort(down.y);
					msg.writeShort(up.x);
					msg.writeShort(up.y);
					msg.send();
				}
			});
			
			stage.addEventListener(Event.ENTER_FRAME, function(e:Event) {
				for each(var o:Object in arrows) {
					if (o.life-- <= 0) {
						arrowContainer.removeChild(o.sprite);
						arrows.splice(arrows.indexOf(o), 1);
					}else {
						o.sprite.alpha = o.life / 60.0;
					}
				}
			});
		}
		
		private function setNumOpponentCards(value:int):void {
			var currentOpponentSize:int = opponentHandLayout.size();
			if (value > currentOpponentSize) {
				while (value != opponentHandLayout.size()) opponentHandLayout.add(cardFactory.getCard("back.jpg", false));
			}else {
				while (value != opponentHandLayout.size()) opponentHandLayout.pop();
			}
		}
		
		private function addCardToHand(cardName:String, foil:Boolean):void {
			var card:Card = cardFactory.getCard(cardName, foil);
			handLayout.add(card);
			
			//set right click menu options
			var menu:ContextMenu = new ContextMenu();
			menu.hideBuiltInItems();
			
			var putBackInDeck:ContextMenuItem = new ContextMenuItem("Place on top of deck");
			putBackInDeck.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent) {
				var index:int = handLayout.remove(card);
				var msg:ServerMessage = new ServerMessage(21);
				msg.writeShort(index);
				msg.send();
			});
			
			menu.customItems.push(putBackInDeck);
			
			card.contextMenu = menu;
		}
		
		private function addCardToField(cardName:String, foil:Boolean, x:int, y:int):void {
			var card:Card = cardFactory.getCard(cardName, foil);
			field.push(card);
			card.x = x;
			card.y = y;
			card.scaleX = card.scaleY = FIELD_SCALE;
			fieldContainer.addChild(card);
			
			card.doubleClickEnabled = true;
			
			var px:Number, py:Number;
			card.addEventListener(MouseEvent.MOUSE_DOWN, function (e:MouseEvent) {
				px = card.x;
				py = card.y;
			});
			card.addEventListener(MouseEvent.DOUBLE_CLICK, function (e:MouseEvent) {
				if (!Card.viewingCard && !isSearchingInDeck) tapCard(card);
			});
			function mouseUp (e:MouseEvent) {
				isDragging = false;
				stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				if (!Card.viewingCard) {
					sendCardDrag(card);
					fieldContainer.setChildIndex(card, fieldContainer.numChildren - 1);
				}
			}
			function mouseMove (e:MouseEvent) {
				isDragging = true;
				if (e.buttonDown) {
					var width:int = Math.abs(card.width);
					var height:int = Math.abs(card.height);
					card.x = px - down.x + e.stageX;
					card.y = py - down.y + e.stageY;
					card.x = Math.min(Math.max(0, card.x), chat.ta.x - card.width);
					card.y = Math.min(Math.max(0, card.y), stage.stageHeight - card.height);
					sendCardDrag(card);
					fieldContainer.setChildIndex(card, fieldContainer.numChildren - 1);
				}
			}
			card.addEventListener(MouseEvent.MOUSE_DOWN, function (e:MouseEvent) {
				if (!Card.viewingCard && !isSearchingInDeck) {
					stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
					stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				}
			});
			
			//set right click menu options
			var menu:ContextMenu = new ContextMenu();
			menu.hideBuiltInItems();
			
			var tap:ContextMenuItem = new ContextMenuItem("Tap");
			tap.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent) {
				tapCard(card);
			});
			var putBackInDeck:ContextMenuItem = new ContextMenuItem("Place on top of deck");
			putBackInDeck.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent) {
				var msg:ServerMessage = new ServerMessage(10);
				msg.writeShort(field.indexOf(card));
				msg.send();
			});
			var putBackInHand:ContextMenuItem = new ContextMenuItem("Place in hand");
			putBackInHand.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent) {
				var msg:ServerMessage = new ServerMessage(12);
				msg.writeShort(field.indexOf(card));
				msg.send();
			});
			var createCounter:ContextMenuItem = new ContextMenuItem("Create new counter");
			createCounter.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent) {
				var msg:ServerMessage = new ServerMessage(14);
				msg.writeShort(card.x);
				msg.writeShort(card.y);
				msg.send();
			});
			
			menu.customItems.push(tap);
			menu.customItems.push(putBackInDeck);
			menu.customItems.push(putBackInHand);
			menu.customItems.push(createCounter);
			
			card.contextMenu = menu;
		}
		
		private function numInDeck(v:int, v2:int):void {
			gameui.draw.label = v + " - " + v2;
		}
				
		private function setCardTapped(index:int, tapped:Boolean):void {
			var card:Card = field[index];
			card.tap = tapped;
		}
		
		private function drawArrow(x0:int, y0:int, x1:int, y1:int):void {
			var theta:Number = Math.atan2(y1 - y0, x1 - x0);
			var headSize:Number = 10;
			
			var sprite:Sprite = new Sprite();
			sprite.graphics.lineStyle(3, 0x0000FF);
			sprite.graphics.moveTo(x0, y0);
			sprite.graphics.lineTo(x1, y1);
			
			sprite.graphics.beginFill(0xFFFFFF);
			sprite.graphics.moveTo(x1 + headSize * Math.cos(theta + Math.PI / 2), y1 + headSize * Math.sin(theta + Math.PI / 2));
			sprite.graphics.lineTo(x1 + headSize * Math.cos(theta - Math.PI / 2), y1 + headSize * Math.sin(theta - Math.PI / 2));
			sprite.graphics.lineTo(x1 + headSize * Math.cos(theta), y1 + headSize * Math.sin(theta));
			sprite.graphics.endFill();
			
			arrowContainer.addChild(sprite);
			
			var o:Object = { sprite:sprite, life:120 };
			arrows.push(o);
		}
		
		private function createCounter(value:int, x:int, y:int):void {
			var c:NumericStepper = new NumericStepper();
			c.maximum = 100;
			c.stepSize = 1;
			c.value = value;
			c.x = x;
			c.y = y;
			counterContainer.addChild(c);
			counters.push(c);
			
			//if counter is a player life counter...
			if (counters.length <= 2) {
				c.x = gameui.search.x;
				c.width = gameui.search.width;
				if (counters.length == 1) {
					c.y = stage.stageHeight - c.height - 5;
				}else {
					c.y = Chat.bufferHeightForGame - c.height - 5;
				}
			}
			
			c.addEventListener(Event.CHANGE, function(e:Event) {
				var msg:ServerMessage = new ServerMessage(15);
				msg.writeShort(counters.indexOf(c));
				msg.writeShort(c.value);
				msg.send();
			});
			
			function dragCounter():void {
				var msg:ServerMessage = new ServerMessage(16);
				msg.writeShort(counters.indexOf(c));
				msg.writeShort(c.x);
				msg.writeShort(c.y);
				msg.send();
			}
			function mouseUp (e:MouseEvent) {
				isDragging = false;
				stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				mouseMove(e);
			}
			function mouseMove (e:MouseEvent) {
				isDragging = true;
				if (e.buttonDown && !Card.viewingCard) {
					c.x = e.stageX - c.width / 2;
					c.y = e.stageY - c.height / 2;
					c.x = Math.min(Math.max(0, c.x), chat.ta.x - c.width);
					c.y = Math.min(Math.max(0, c.y), stage.stageHeight - c.height);
					dragCounter();
					counterContainer.setChildIndex(c, counterContainer.numChildren - 1);
				}
			}
			c.addEventListener(MouseEvent.MOUSE_DOWN, function (e:MouseEvent) {
				//if this counter is not a life counter
				if (counters.indexOf(c) > 1) {
					stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
					stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
				}
			});
			
			//set right click menu options
			var menu:ContextMenu = new ContextMenu();
			menu.hideBuiltInItems();
			
			var deleteCounter:ContextMenuItem = new ContextMenuItem("Delete Counter");
			deleteCounter.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent) {
				//if this counter is not a life counter
				if (counters.indexOf(c) > 1) {
					var msg:ServerMessage = new ServerMessage(24);
					msg.writeShort(counters.indexOf(c));
					msg.send();
				}
			});
			
			menu.customItems.push(deleteCounter);
			
			c.contextMenu = menu;
		}
		
		private function setCounter(index:int, value:int):void {
			counters[index].value = value;
		}
		
		private function moveCounter(index:int, x:int, y:int):void {
			counters[index].x = x;
			counters[index].y = y;
		}
		
		private var isSearchingInDeck:Boolean = false;
		
		private function beginSearchingDeck(reader:ByteArray):void {
			isSearchingInDeck = true;
			searchDeckLayout.clear();
			
			var size:int = reader.readShort();
			var dic:Dictionary = new Dictionary();
			while (reader.bytesAvailable) {
				var card:Card = cardFactory.getCard(reader.readUTF(), reader.readBoolean());
				searchDeckLayout.add(card);
				
				//set right click menu options
				var menu:ContextMenu = new ContextMenu();
				menu.hideBuiltInItems();
				
				var toField:ContextMenuItem = new ContextMenuItem("Move to field");
				toField.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent) {
					var msg:ServerMessage = new ServerMessage(22);
					msg.writeShort(searchDeckLayout.remove(dic[e.target]));
					msg.send();
				});
				
				var toHand:ContextMenuItem = new ContextMenuItem("Move to hand");
				toHand.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, function(e:ContextMenuEvent) {
					var msg:ServerMessage = new ServerMessage(23);
					msg.writeShort(searchDeckLayout.remove(dic[e.target]));
					msg.send();
				});
				
				menu.customItems.push(toField);
				menu.customItems.push(toHand);
				
				card.contextMenu = menu;
				
				dic[toField] = card;
				dic[toHand] = card;
			}
			searchDeckLayout.updateLayout();
			fieldContainer.alpha = handLayout.alpha = opponentHandLayout.alpha = 0.6;
		}
		
		[Embed(source='shuffle.mp3')]
		private var shuffleSound:Class;
		private var sound:Sound;
		public function playShuffleSfx():void {
			sound = (new shuffleSound()) as Sound;
			sound.play();
		}
		
		//server communication functions
		
		private function sendChatMessage():void {
			if (chat.ta.text.length != 0) {
				var msg:ServerMessage = new ServerMessage(2);
				msg.writeUTF(chat.ta.text);
				msg.send();
				chat.ta.text = "";
			}
		}
		
		private function requestGameWith(un:String):void {
			var msg:ServerMessage = new ServerMessage(3);
			msg.writeUTF(un);
			msg.send();
		}
		
		private function tapCard(card:Sprite):void {
			var msg:ServerMessage = new ServerMessage(9);
			msg.writeInt(field.indexOf(card));
			msg.send();
		}
		
		private function sendCardDrag(card:Sprite):void {
			var index:int = field.indexOf(card);
			var msg:ServerMessage = new ServerMessage(8);
			msg.writeShort(index);
			msg.writeShort(card.x);
			msg.writeShort(card.y);
			msg.send();
		}
	}
}