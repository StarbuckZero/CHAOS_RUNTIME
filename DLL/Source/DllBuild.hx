import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

/** Keep OpenFL's generated startup, but leave its lifetime under the C++ host. */
class DllBuild {
    public static macro function configureBackend():Array<Field> {
        var fields = Context.getBuildFields();
        var loops = 0;
        function replaceLoop(expr:Expr):Expr {
            return switch expr.expr {
                case ECall({expr: EField({expr: EConst(CIdent("NativeCFFI"))}, "lime_application_exec")}, _):
                    loops++;
                    // Lime's blocking SDL loop assumes Sys.exit terminates the process.
                    // Use its existing init/update API so window shutdown returns to C++.
                    macro {
                        NativeCFFI.lime_application_init(handle);
                        while (lime.app.Application.current == parent && NativeCFFI.lime_application_update(handle)) {}
                        0;
                    };
                default: ExprTools.map(expr, replaceLoop);
            };
        }
        for (field in fields) if (field.name == "exec") switch field.kind {
            case FFun(fn): fn.expr = replaceLoop(fn.expr);
            default:
        }
        if (loops != 1) Context.fatalError("Expected one native application loop; review DLL event pumping for this Lime version.", Context.currentPos());
        return fields;
    }

    public static macro function configureSystem():Array<Field> {
        var fields = Context.getBuildFields();
        var exits = 0;
        function removeProcessExit(expr:Expr):Expr {
            return switch expr.expr {
                case ECall({expr: EField({expr: EConst(CIdent("Sys"))}, "exit")}, _):
                    exits++;
                    macro {};
                default: ExprTools.map(expr, removeProcessExit);
            };
        }
        for (field in fields) if (field.name == "exit") switch field.kind {
            case FFun(fn): fn.expr = removeProcessExit(fn.expr);
            default:
        }
        if (exits != 1) Context.fatalError("Expected one Sys.exit in Lime System.exit; review DLL shutdown for this Lime version.", Context.currentPos());
        return fields;
    }

    public static macro function configure():Array<Field> {
        var fields = Context.getBuildFields();
        var exits = 0;
        function removeExit(expr:Expr):Expr {
            return switch expr.expr {
                case ECall({expr: EField({expr: EField({expr: EField({expr: EConst(CIdent("lime"))}, "system")}, "System")}, "exit")}, _):
                    exits++;
                    macro {};
                default: ExprTools.map(expr, removeExit);
            };
        }
        for (field in fields) switch field.kind {
            case FFun(fn):
                if (field.name == "main") fn.expr = macro { var library:Class<ChaosLibrary> = ChaosLibrary; };
                else if (field.name == "create") fn.expr = removeExit(fn.expr);
            default:
        }
        if (exits != 1) Context.fatalError("Expected one OpenFL process exit in ApplicationMain.create; review DLL startup for this OpenFL version.", Context.currentPos());
        return fields;
    }
}
