package;

import com.chaos.engine.CommandDispatch;
import com.chaos.engine.CoreEngine;
import com.chaos.engine.Global;
import com.chaos.engine.events.EventConfigurationStore;
import com.chaos.engine.events.EventPlugin;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;

/** Standard hxcpp C++ entry points. The host owns the OpenFL application and stage. */
@:keep
class ChaosLibrary {
    private static var root:EmbeddedRoot;

    // hxRunLibrary boots Haxe without creating a window or starting an event loop.
    public static function main():Void {}

    /** Attach one runtime to a staged container; project assets use the host's working directory. */
    public static function attach(parent:DisplayObjectContainer, projectJSON:String):CoreEngine {
        if (root != null) throw "A CHAOS runtime is already attached.";
        if (parent == null || parent.stage == null) throw "The parent must belong to an OpenFL stage.";
        if (projectJSON == null) throw "Project JSON is required.";
        var project:Dynamic = haxe.Json.parse(projectJSON);
        if (project == null || !Std.isOfType(project.items, Array)) throw "Project JSON must contain an items array.";
        root = new EmbeddedRoot(parent);
        try {
            root.load(projectJSON);
        } catch (error:Dynamic) {
            shutdown();
            throw error;
        }
        return root;
    }

    /** Detach CHAOS before destroying the host stage. Haxe's process runtime remains resident. */
    public static function shutdown():Void {
        if (root == null) return;
        root.release();
        root = null;
    }
}

@:access(com.chaos.engine.CoreEngine)
private class EmbeddedRoot extends Main {
    public function new(parent:DisplayObjectContainer) {
        // CoreEngine needs a stage during construction, like OpenFL's DocumentClass.
        parent.addChild(this);
        super(false);
    }

    public function load(projectJSON:String):Void {
        eventConfigurations = new EventConfigurationStore();
        eventPlugin = new EventPlugin(displayArea);
        eventPlugin.afterAction = function() eventPlugin.refresh(eventConfigurations);
        displayArea.addEventListener(Event.ADDED, childAdded);
        reader.setData(projectJSON);
    }

    private function childAdded(event:Event):Void {
        if (Std.isOfType(event.target, com.chaos.ui.chart.ChartBase))
            eventPlugin.refresh(eventConfigurations);
    }

    public function release():Void {
        if (eventPlugin != null) eventPlugin.dispose();
        displayArea.removeEventListener(Event.ADDED, childAdded);
        stage.removeEventListener(Event.RESIZE, onResize);
        com.chaos.utils.ThreadManager.removeEventTimer((cast reader:com.chaos.engine.loader.Reader).thread);
        reader.onDataParse = null;
        reader.onError = null;
        CommandDispatch.removeEngineListener(onEngineEvent);
        releaseEvents(this);
        if (Global.mainDisplyArea == this) {
            Global.mainDisplyArea = null;
            Global.currentLayer = null;
        }
        if (parent != null) parent.removeChild(this);
    }

    private static function releaseEvents(node:openfl.display.DisplayObject):Void {
        motion.Actuate.stop(node);
        if (Std.isOfType(node, com.chaos.ui.classInterface.IBaseUI))
            CommandDispatch.removeAllEvents(cast node);
        if (Std.isOfType(node, DisplayObjectContainer)) {
            var container:DisplayObjectContainer = cast node;
            for (i in 0...container.numChildren) releaseEvents(container.getChildAt(i));
        }
    }
}
