package 
{
	/**
	 * @author seaders
	 */
	
	import com.greygreen.net.p2p.P2PClient;
	import com.greygreen.net.p2p.events.P2PEvent;
	import com.greygreen.net.p2p.model.P2PConfig;
	import com.greygreen.net.p2p.model.P2PPacket;
	
	import feathers.controls.Button;
	import feathers.controls.Label;
	import feathers.controls.List;
	import feathers.controls.ScrollContainer;
	import feathers.controls.TextArea;
	import feathers.controls.TextInput;
	import feathers.core.FeathersControl;
	import feathers.data.ListCollection;
	import feathers.events.FeathersEventType;
	import feathers.layout.HorizontalLayout;
	import feathers.layout.VerticalLayout;
	import feathers.themes.MetalWorksMobileTheme;
	
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Sprite;
	import starling.events.Event;
	
	public class ChatMain extends Sprite
	{
		private const p2pclient:P2PClient = new P2PClient();
		
		/**
		 *  User to chat mapping (use peerID as a key or 'all' keyword for public chat)
		 */
		private var _storage:Object = {
			"all": {label: "all", peerID: "all", text: ""}
		}
		
		private var _currentChat:String = "all";
		
		private var _my_name:String = "chatter-box-" + Math.floor(1000 * Math.random());
		private var push_btn:Button;
		private var users:List;
		private var title:Label;
		private var inputField:TextInput;
		private var textArea:TextArea;
		
		private var _listProvider:ListCollection = new ListCollection();
		
		private function debug(s:String):void
		{
			trace(s);
		}
		
		public function centralize(
			parent:DisplayObjectContainer, child:DisplayObject,
			centreH:Boolean=true, centreV:Boolean=false,
			centreByParent:Boolean=false
		):void
		{
			parent.addChild(child);
			if(child is FeathersControl)
			{
				(child as FeathersControl).validate();
			}
			if(!centreH && !centreV)
			{
				return;
			}
			
			var w:Number;
			var h:Number;
			if(!centreByParent)
			{
				w = this.stage.stageWidth;
				h = this.stage.stageHeight;
			}
			else
			{
				w = parent.width;
				h = parent.height;
			}
			
			if(centreH)
			{
				child.x = (w / 2) - (child.width / 2);
			}
			if(centreV)
			{
				child.y = (h / 2) - (child.height / 2);
			}
		}
		
		public function ChatMain()
		{
			//we'll initialize things after we've been added to the stage
			this.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
		}
		
		/**
		 * The Feathers Button control that we'll be creating.
		 */
		protected var button:Button;
		
		/**
		 * Where the magic happens. Start after the main class has been added
		 * to the stage so that we can access the stage property.
		 */
		protected function addedToStageHandler(event:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);
			new MetalWorksMobileTheme();
			
			users = new List();
			addChild(users);
			users.validate();
			
			users.isSelectable = true;
			users.dataProvider = _listProvider;
			
			users.width = 150;
			users.height = this.stage.stageHeight;
			users.addEventListener(Event.CHANGE, listClick);
			
			const vlayout:VerticalLayout = new VerticalLayout();
			
			var vgroup:ScrollContainer = new ScrollContainer();
			vgroup.layout = vlayout;
			
			addChild(vgroup);
			vgroup.x = 155;
			vgroup.width = this.stage.stageWidth - vgroup.x;
			vgroup.height = this.stage.stageHeight;
			
			title = new Label();
			title.text = ' ';
			vgroup.addChild(title);
			title.validate();
			title.width = vgroup.width;
			title.height = 30;
			
			textArea = new TextArea();
			vgroup.addChild(textArea);
			textArea.validate();
			textArea.width = vgroup.width;
			
			const hlayout:HorizontalLayout = new HorizontalLayout();
			
			var hgroup:ScrollContainer = new ScrollContainer();
			hgroup.layout = hlayout;
			vgroup.addChild(hgroup);
			hgroup.width = vgroup.width;
			
			inputField = new TextInput();
			hgroup.addChild(inputField);
			inputField.validate();
			inputField.text = 'sample';
			inputField.addEventListener(FeathersEventType.ENTER, push);
			
			push_btn = new Button();
			hgroup.addChild(push_btn);
			push_btn.validate();
			push_btn.horizontalAlign = Button.HORIZONTAL_ALIGN_CENTER;
			push_btn.label = 'Push';
			
			inputField.width = hgroup.width - push_btn.width - 10;
			
			hgroup.validate();
			
			textArea.height = vgroup.height - (title.height + hgroup.height);
			
			push_btn.addEventListener(Event.TRIGGERED, push);
			
			setupConnection();
		}
		
		private function setupConnection():void {
			
			p2pclient.addEventListener(P2PEvent.FAILED, onFailure);
			p2pclient.addEventListener(P2PEvent.CONNECTED, onConnect);
			p2pclient.addEventListener(P2PEvent.STATE_RESTORED, onStateRestored);
			p2pclient.addEventListener(P2PEvent.STATE_RESTORE_FAILED, onFailure);
			p2pclient.addEventListener(P2PEvent.PEER_CONNECTED, userJoin);
			p2pclient.addEventListener(P2PEvent.PEER_DISCONNECTED, userLeave);
			
			p2pclient.listen(messageReceived, "message");
			
			p2pclient.listen(userRegister, "user");
			
			p2pclient.connect(new P2PConfig({
				groupName: "p2p/chat/1",
				saveState: "true"
			}));
			
		}
		
		private function userJoin(e:P2PEvent):void {
			if (!_storage[e.info.peerID]) {  // we have't received user registration
				_storage[e.info.peerID] = {peerID: e.info.peerID, text: ""};
			} else { // we've already received user info (obviously on restore state); than add to list
				_listProvider.addItem(_storage[e.info.peerID]);
			}
		}
		
		private function userLeave(e:P2PEvent):void {
			if (_storage[e.info.peerID]) {
				
				_listProvider.getItemIndex(_storage[e.info.peerID]) > -1 && _listProvider.removeItemAt(_listProvider.getItemIndex(_storage[e.info.peerID]));
				
				delete _storage[e.info.peerID];
				
				if (_currentChat == e.info.peerID) switchTo("all");
				
			}
		}
		
		private function onStateRestored(e:P2PEvent):void {
			
			restoreFromArray(e.info.state);
			
			p2pclient.receive = true;
			
			push_btn.isEnabled = true;
			
			switchTo("all");
			
			p2pclient.send({label: _my_name, peerID: p2pclient.peerID}, "user");
			
		}
		
		private function onConnect(e:P2PEvent):void {
			
			debug('P2P connection established');
			
			_listProvider.addItem(_storage["all"]);
			
		}
		
		private function onFailure(e:P2PEvent):void {
			debug('P2P connection failed');
		}
		
		
		private function userRegister(p:P2PPacket):void {
			
			if (!_storage[p.senderId]) {
				_storage[p.data.peerID] = {peerID: p.data.peerID, text: ""};
				
				// we must ensure that user is really connected so waiting for PEER_CONNECT
				
			} else {
				
				_storage[p.senderId]["label"] = p.data.label;
				
				_listProvider.addItem(_storage[p.senderId]);
			}
		}
		
		private function messageReceived(p:P2PPacket):void {
			
			if (p.data.chat != "all" && !_storage[p.senderId]) return;
			
			const message:String = p.data.name + ": " + p.data.text + "\n";
			
			if(p.data.chat == "all") _storage["all"]["text"] += message;
			else    _storage[p.senderId]["text"] += message;
			
			const valid:Boolean = (p.senderId == _currentChat) ||  // private chat: compare sender with current
				(p.data.chat == _currentChat) ||    // it is possible only if _currentChat == "all"
				(p.data.chat == p2pclient.peerID); 
			if (valid)
				textArea.text += message;
			
			trace(valid, message, p.senderId, p.data.chat);
			p = null;
		}
		
		
		private function restoreFromArray(arr:Array):void {
			
			for each(var p:P2PPacket in arr) {
				if (p && p.type == "user") userRegister(p);
				else if (p && p.type == "message") messageReceived(p);
			}
			
		}
		
		
		private function switchTo(id:String):void {
			
			if (!_storage[id]) return;
			
			textArea.text = _storage[id]["text"];
			
			title.text = _storage[id]['label'];
			
			_currentChat = id;
			
		}
		
		private function push():void {
			
			if (!inputField.text)  return;
			
			p2pclient.send({chat: _currentChat, name: _my_name, text: inputField.text}, "message", _currentChat === "all", _currentChat === "all" ? "" : _currentChat);
			
			_storage[_currentChat]["text"] += _my_name + ": " + inputField.text + "\n";
			
			textArea.text += _my_name + ": " + inputField.text + "\n";
			
			inputField.text = "";
			
		}
		
		
		private function listClick():void {
			if(null != users.selectedItem)
			{
				switchTo(users.selectedItem.peerID);
			}
		}
	}	
}

