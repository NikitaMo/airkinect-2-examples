package com.as3nui.nativeExtensions.air.kinect.examples.away3D
{
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.controllers.HoverController;
	import away3d.core.math.Quaternion;
	import away3d.entities.Mesh;
	import away3d.lights.DirectionalLight;
	import away3d.materials.ColorMaterial;
	import away3d.materials.MaterialBase;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.primitives.CubeGeometry;
	
	import com.as3nui.nativeExtensions.air.kinect.Kinect;
	import com.as3nui.nativeExtensions.air.kinect.KinectConfig;
	import com.as3nui.nativeExtensions.air.kinect.data.SkeletonJoint;
	import com.as3nui.nativeExtensions.air.kinect.data.User;
	import com.as3nui.nativeExtensions.air.kinect.events.KinectEvent;
	import com.as3nui.nativeExtensions.air.kinect.events.UserEvent;
	import com.as3nui.nativeExtensions.air.kinect.examples.DemoBase;
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	public class JointCubesDemo extends DemoBase
	{
		
		private static const SCALE:Number = 100;
		
		private var scene:Scene3D;
		private var camera:Camera3D;
		private var view:View3D;
		private var cameraController:HoverController;
		private var light:DirectionalLight;
		private var direction:Vector3D;
		
		private var lastPanAngle:Number;
		private var lastTiltAngle:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private var move:Boolean;
		
		private var kinect:Kinect;
		
		private var skeletonViewsDictionary:Dictionary;
		
		private var stageRef:Stage;
		private var lightPicker:StaticLightPicker;
		
		override protected function startDemoImplementation():void
		{
			trace("[JointCubesDemo] startDemo");
			
			scene = new Scene3D();
			
			camera = new Camera3D();
			
			skeletonViewsDictionary = new Dictionary();
			
			view = new View3D();
			view.backgroundColor = 0xFFFFFF;
			view.scene = scene;
			view.camera = camera;
			addChild(view);
			
			cameraController = new HoverController(camera, null, 0, 20, 250, 10);
			
			light = new DirectionalLight(-1, -1, 1);
			direction = new Vector3D(-1, -1, 1)
			scene.addChild(light);
			
			lightPicker = new StaticLightPicker([light]);
			
			addEventListener(Event.ENTER_FRAME, enterFrameHandler, false, 0, true);
			stageRef = stage;
			stageRef.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown, false, 0, true);
			stageRef.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
			
			if(Kinect.isSupported())
			{
				kinect = Kinect.getKinect();
				
				kinect.addEventListener(KinectEvent.STARTED, kinectStartedHandler, false, 0, true);
				kinect.addEventListener(KinectEvent.STOPPED, kinectStoppedHandler, false, 0, true);
				kinect.addEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler, false, 0, true);
				kinect.addEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler, false, 0, true);
				
				var config:KinectConfig = new KinectConfig();
				config.skeletonEnabled = true;
				
				kinect.start(config);
			}
		}
		
		protected function kinectStartedHandler(event:KinectEvent):void
		{
			trace("[JointCubesDemo] kinect started");
		}
		
		protected function kinectStoppedHandler(event:KinectEvent):void
		{
			trace("[JointCubesDemo] kinect stopped");
		}
		
		protected function usersWithSkeletonRemovedHandler(event:UserEvent):void
		{
			trace("[JointCubesDemo] users removed:", event.users);
			//remove cubes for the removed users
			for each(var removedUser:User in event.users)
			{
				var boxes:Vector.<Mesh> = skeletonViewsDictionary[removedUser.trackingID];
				if(boxes != null)
				{
					for each(var box:Mesh in boxes)
					{
						scene.removeChild(box);
					}
				}
				delete skeletonViewsDictionary[removedUser.trackingID];
			}
		}
		
		protected function usersWithSkeletonAddedHandler(event:UserEvent):void
		{
			trace("[JointCubesDemo] users added:", event.users);
			//create cubes for the added skeletons
			var m:MaterialBase = new ColorMaterial(0xFF0000);
			m.lightPicker = lightPicker;
			for each(var addedUser:User in event.users)
			{
				var boxes:Vector.<Mesh> = new Vector.<Mesh>();
				for each(var addedSkeletonJoint:SkeletonJoint in addedUser.skeletonJoints)
				{
					var box:Mesh = new Mesh(new CubeGeometry(10, 10, 10), m);
					scene.addChild(box);
					boxes.push(box);
				}
				skeletonViewsDictionary[addedUser.trackingID] = boxes;
			}
		}
		
		override protected function stopDemoImplementation():void
		{
			trace("[JointCubesDemo] stopDemo");
			removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
			stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stageRef.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			if(kinect != null)
			{
				kinect.stop();
				kinect.removeEventListener(KinectEvent.STARTED, kinectStartedHandler);
				kinect.removeEventListener(KinectEvent.STOPPED, kinectStoppedHandler);
				kinect.removeEventListener(UserEvent.USERS_WITH_SKELETON_ADDED, usersWithSkeletonAddedHandler);
				kinect.removeEventListener(UserEvent.USERS_WITH_SKELETON_REMOVED, usersWithSkeletonRemovedHandler);
			}
			view.dispose();
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			lastPanAngle = cameraController.panAngle;
			lastTiltAngle = cameraController.tiltAngle;
			lastMouseX = stage.mouseX;
			lastMouseY = stage.mouseY;
			move = true;
			stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse up listener for navigation
		 */
		private function onMouseUp(event:MouseEvent):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		/**
		 * Mouse stage leave listener for navigation
		 */
		private function onStageMouseLeave(event:Event):void
		{
			move = false;
			stage.removeEventListener(Event.MOUSE_LEAVE, onStageMouseLeave);
		}
		
		protected function enterFrameHandler(event:Event):void
		{
			if(move)
			{
				cameraController.panAngle = 0.3 * (stage.mouseX - lastMouseX) + lastPanAngle;
				cameraController.tiltAngle = 0.3 * (stage.mouseY - lastMouseY) + lastTiltAngle;
			}
			
			if(kinect != null && kinect.usersWithSkeleton.length > 0)
			{
				for each(var skeleton:User in kinect.usersWithSkeleton)
				{
					var boxes:Vector.<Mesh> = skeletonViewsDictionary[skeleton.trackingID];
					if(boxes != null)
					{
						for(var i:uint = 0; i < skeleton.skeletonJoints.length; i++)
						{
							boxes[i].x = skeleton.skeletonJoints[i].positionRelative.x * SCALE;
							boxes[i].y = skeleton.skeletonJoints[i].positionRelative.y * SCALE;
							boxes[i].z = skeleton.skeletonJoints[i].positionRelative.z * -SCALE;
						}
					}
				}
			}
			
			view.render();
		}
		
		private function getBoneOrientationFromKinectJoint(joint:SkeletonJoint, invertX:Boolean = false, invertY:Boolean = false, invertZ:Boolean = false, rotationX:Number = 0, rotationY:Number = 0, rotationZ:Number = 0):Quaternion
		{
			var q:Quaternion = new Quaternion();
			var data:Vector.<Number> = new Vector.<Number>(16, true);
			data[0] = joint.orientation[0];
			data[1] = joint.orientation[3];
			data[2] = joint.orientation[6];
			data[3] = 0;
			data[4] = joint.orientation[1];
			data[5] = joint.orientation[4];
			data[6] = joint.orientation[7];
			data[7] = 0;
			data[8] = joint.orientation[2];
			data[9] = joint.orientation[5];
			data[10] = joint.orientation[8];
			data[11] = 0;
			data[12] = 0;
			data[13] = 0;
			data[14] = 0;
			data[15] = 1;
			
			if(invertX)
			{
				data[1] = -joint.orientation[3];
				data[2] = -joint.orientation[6];
				data[4] = -joint.orientation[1];
				data[8] = -joint.orientation[2];
			}
			
			if(invertY)
			{
				data[1] = -joint.orientation[3];
				data[4] = -joint.orientation[1];
				data[6] = -joint.orientation[7];
				data[9] = -joint.orientation[5];
			}
			
			if(invertZ)
			{
				data[2] = -joint.orientation[6];
				data[6] = -joint.orientation[7];
				data[8] = -joint.orientation[2];
				data[9] = -joint.orientation[5];
			}
			
			q.fromMatrix(new Matrix3D(data));
			
			var v:Vector3D = q.toEulerAngles();
			
			if(rotationX != 0)
			{
				v.x += rotationX;
			}
			
			if(rotationY != 0)
			{
				v.y += rotationY;
			}
			
			if(rotationZ != 0)
			{
				v.z += rotationZ;
			}
			
			q.fromEulerAngles(v.x, v.y, v.z);
			
			return q;
		}
		
		override protected function layout():void
		{
			if(view != null)
			{
				view.width = explicitWidth;
				view.height = explicitHeight;
			}
		}
	}
}