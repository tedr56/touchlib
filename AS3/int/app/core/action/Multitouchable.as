﻿// This will be a low level class that handles the basics of tracking multiple blob id's that may affect this Sprite. This includes touching this Sprite,
// moving over this sprite. It handles keeping a list of blob id's that are alive and firing off event handler functions. When you extend this class
// you just implement the event handler funcs. This class will be used to greatly simplify the paint canvas and could also be used to simplify 'RotatableScalable'.

package app.core.action
{
	import flash.display.*;		
	import flash.events.*;
	import com.touchlib.*;		
	import flash.geom.Point;
	
	public class Multitouchable extends MovieClip
	{
		protected var blobs:Array;		// blobs we are currently interacting with			
		
		function Multitouchable()
		{
			blobs = new Array();
		
			this.addEventListener(TUIOEvent.TUIO_MOVE, this.moveHandler, false, 0, true);			
			this.addEventListener(TUIOEvent.TUIO_DOWN, this.downHandler, false, 0, true);						
			this.addEventListener(TUIOEvent.TUIO_UP, this.upHandler, false, 0, true);									
			this.addEventListener(TUIOEvent.TUIO_OVER, this.rollOverHandler, false, 0, true);									
			this.addEventListener(TUIOEvent.TUIO_OUT, this.rollOutHandler, false, 0, true);		
			
			this.addEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveHandler, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler, false, 0, true);			
			this.addEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler, false, 0, true);
		}

		function idExists(id:int):Boolean
		{
			for(var i=0; i<blobs.length; i++)
			{
				if(blobs[i].id == id)
					return true;
			}			
			
			return false;
		}
	
		function addBlob(id:int, origX:Number, origY:Number, c:Boolean):void
		{
			for(var i=0; i<blobs.length; i++)
			{
				if(blobs[i].id == id)
				{
					// blob exists.
					return;
				}
			}

			trace("Creating new blob " + id + " " + origX + " " + origY);
			blobs.push( {id: id, clicked:c, origX: origX, origY:origY, clicked:c, history:new Array(new Point(origX, origY)), dX:0.0, dY:0.0} );
			
			handleBlobCreated(id, origX, origY);			
		}
		
		function removeBlob(id:int):void
		{
			for(var i=0; i<blobs.length; i++)
			{
				if(blobs[i].id == id) 
				{
					trace("blob removed " + id);										
					blobs.splice(i, 1);		
					handleBlobRemoved(id);					

					return;
				}
			}
		}	
		
		private function updateBlob(id:int, origX:Number, origY:Number):void
		{
			for(var i:int = 0; i<blobs.length; i++)
			{
				if(blobs[i].id == id) 
				{
					blobs[i].history.push(new Point(origX, origY));
					if(blobs[i].history.length >= 2)
					{
						var len:int = blobs[i].history.length;
						blobs[i].dX = blobs[i].history[len-1].x - blobs[i].history[len-2].x;
						blobs[i].dY = blobs[i].history[len-1].y - blobs[i].history[len-2].y;						
//						trace("X: " + blobs[i].history[len-1].x + "," + blobs[i].history[len-2].x);
						//trace("DELTA : " + blobs[i].dX + "," + blobs[i].dY);
					}
					
//					trace(blobs[i].history.length);
					return;
				}
			}
		}			
		
		function getBlobInfo(id:int):Object
		{
			for(var i=0; i<blobs.length; i++)
			{
				if(blobs[i].id == id)
					return blobs[i];
			}			
			
			return null;
		}
		
		public function downHandler(e:TUIOEvent):void
		{
			if(e.stageX == 0 && e.stageY == 0)
				return;			
				
			TUIO.listenForObject(e.ID, this);							
			
			var curPt:Point = parent.globalToLocal(new Point(e.stageX, e.stageY));												

			addBlob(e.ID, curPt.x, curPt.y, true);
			
			handleDownEvent(e.ID, curPt.x, curPt.y, e.target);
			e.stopPropagation();			
		}

		
		public function upHandler(e:TUIOEvent):void
		{
			handleUpEvent(e.ID);
			removeBlob(e.ID);
			e.stopPropagation();
		}		
		
		public function moveHandler(e:TUIOEvent):void
		{
			if(e.stageX == 0 && e.stageY == 0)
				return;			
			
			var curPt:Point = parent.globalToLocal(new Point(e.stageX, e.stageY));															
			
			if(!idExists(e.ID))
			{
				trace("Error, shouldn't this blob already be in the list?");
				//TUIO.listenForObject(e.ID, this);			
				addBlob(e.ID, curPt.x, curPt.y, false);
			} else {
				updateBlob(e.ID, curPt.x, curPt.y);				
			}
			
			handleMoveEvent(e.ID, curPt.x, curPt.y, e.target);			
			
			e.stopPropagation();						
		}		
		
		public function mouseDownHandler(e:MouseEvent):void
		{
			trace("Mouse down");
			var curPt:Point = parent.globalToLocal(new Point(e.stageX, e.stageY));			
			addBlob(0, curPt.x, curPt.y, true);
			
			handleDownEvent(0, curPt.x, curPt.y, e.target);
			
			e.stopPropagation();					
		}
		
		public function mouseMoveHandler(e:MouseEvent):void
		{
			var curPt:Point = parent.globalToLocal(new Point(e.stageX, e.stageY));						
			
			if(!idExists(0))
			{
				return;				
			} else {
				updateBlob(0, curPt.x, curPt.y);				
			}
			
			handleMoveEvent(0, curPt.x, curPt.y, e.target);
			
			e.stopPropagation();
		}		
		
		public function mouseUpHandler(e:MouseEvent):void
		{
			handleUpEvent(0);
			removeBlob(0);			
			e.stopPropagation();	
		}		
		
		public function rollOverHandler(e:TUIOEvent):void
		{
			if(e.stageX == 0 && e.stageY == 0)
				return;			
			
			var curPt:Point = parent.globalToLocal(new Point(e.stageX, e.stageY));																		
			
			if(!idExists(e.ID))
			{
				TUIO.listenForObject(e.ID, this);			
				addBlob(e.ID, curPt.x, curPt.y, false);
			}

			handleRollOverEvent(e.ID, curPt.x, curPt.y);			
			
			e.stopPropagation();									
		}
		
		public function rollOutHandler(e:TUIOEvent):void
		{
			if(e.stageX == 0 && e.stageY == 0)
				return;			
		
		// FIXME: only remove if not clicked?
			var curPt:Point = parent.globalToLocal(new Point(e.stageX, e.stageY));												
			handleRollOutEvent(e.ID, curPt.x, curPt.y);			
			
			//if(!getBlobInfo(e.id).clicked)
			//	removeBlob(e.ID);			
			
			e.stopPropagation();									
		}		
		
		
		//////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/* override these events */
		
		public function handleBlobCreated(id:int, mx:Number, my:Number)
		{
		}
		
		public function handleBlobRemoved(id:int)
		{
		}		
		
		public function handleDownEvent(id:int, mx:Number, my:Number, targetObj)
		{
		}
		
		public function handleUpEvent(id:int)
		{
		}
		
		public function handleRollOverEvent(id:int, mx:Number, my:Number)
		{
		}
		
		public function handleRollOutEvent(id:int, mx:Number, my:Number)
		{
		}				

		public function handleMoveEvent(id:int, mx:Number, my:Number, targetObj)
		{
//			trace("Handle move event");
		}
	}
}