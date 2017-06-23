package thx.schema.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import thx.schema.macro.Error.*;
import thx.schema.macro.TypeReference;
using thx.Arrays;

class SchemaBuilder {
  public static function lookupSchema(typeReference: TypeReference, typeSchemas: Map<String, Expr>): Expr {
    var type = typeReference.toString();
    if(typeSchemas.exists(type)) {
      return typeSchemas.get(type);
    } else {
      var path = TypeBuilder.ensure(typeReference, typeSchemas);
      return macro $p{path};
    }
  }

  public static function generateSchema(typeReference: TypeReference, typeSchemas: Map<String, Expr>): Expr {
    return switch [typeReference.asType(), typeReference] {
      case [TInst(_.get() => cls, _),     Path(classPath)]: generateClassSchema(cls,    classPath, typeSchemas);
      case [TEnum(_.get() => enm, _),     Path(classPath)]: generateEnumSchema(enm,     classPath, typeSchemas);
      case [TAbstract(_.get() => abs, _), Path(classPath)]: generateAbstractSchema(abs, classPath, typeSchemas);
      case [TAnonymous(_.get() => anon),  Object(fields)]:  generateAnonSchema(anon,    fields,    typeSchemas);
      case _: fatal('Cannot generate schema for unsupported type ${typeReference.toString()}');
    }
  }

  static function generateClassSchema(cls: ClassType, classPath: Path, typeSchemas: Map<String, Expr>) {
    // generate constructor function
    // TODO
    var fields = cls.fields.get();
    var n = fields.length;
    return if(n == 0) {
      var path = classPath.parts();
      macro thx.schema.SimpleSchema.object(PropsBuilder.Pure(Type.createEmptyInstance($p{path})));
    } else {
      var constructor = generateClassConstructorF(fields.map(classFieldToFunctionArgument), classPath);
      // generate fields
      var properties = fields.map(createPropertyFromClassField.bind(classPath, typeSchemas, _));
      // capture apN
      var apNArgs = [constructor].concat(properties);
      var apN = 'ap$n';

      // return schema
      var body = macro thx.schema.SimpleSchema.object(thx.schema.SchemaDSL.$apN($a{apNArgs}));
      body;
    }
  }

  static function classFieldToFunctionArgument(cf: ClassField): FunctionArgument {
    return {
      ctype: TypeTools.toComplexType(cf.type),
      opt: false,
      name: cf.name
    };
  }

  static function generateClassConstructorF(args: Array<FunctionArgument>, classPath: Path) {
    var path = classPath.parts(),
        bodyParts = [
            macro var inst = Type.createEmptyInstance($p{path})
          ]
          .concat(args.map(arg -> macro Reflect.setField(inst, $v{arg.name}, $i{arg.name})))
          .append(macro return inst);
    return createFunction("createInstance" + classPath.toIdentifier(), args, macro $b{bodyParts}, classPath.asComplexType(), []);
  }

  static function generateEnumSchema(enm: EnumType, typeReference: Path, typeSchemas: Map<String, Expr>) {
    return macro null; // TODO
  }

  static function generateAbstractSchema(abs: AbstractType, typeReference: Path, typeSchemas: Map<String, Expr>) {
    return macro null; // TODO
  }

  static function generateAnonSchema(anon: AnonType, typeReference: Array<Field>, typeSchemas: Map<String, Expr>) {
    return macro null; // TODO
  }

  static function createFunction(name: Null<String>, args: Array<FunctionArgument>, body: Expr, returnType: Null<ComplexType>, typeParams: Array<String>): Expr {
    return createExpressionFromDef(EFunction(name, {
      args: args.map(a -> ({
        name: a.name,
        type: a.ctype,
        opt: a.opt,
        meta: null,
        value: null
      } : FunctionArg)),
      ret: returnType,
      expr: body,
      params : typeParams.map(n -> {
        name: n,
        constraints: null,
        params: null,
        meta: null
      })
    }));
  }

  static function createExpressionFromDef(e: ExprDef) {
    return {
      expr: e,
      pos: Context.currentPos()
    };
  }

  static function createPropertyFromClassField(classPath: Path, typeSchemas: Map<String, Expr>, cf: ClassField): Expr {
    var argType = TypeReference.fromType(cf.type),
        argName = cf.name;
    return createProperty(classPath, argType, argName, typeSchemas);
  }

  // static function createProperty(classPath: ComplexType, map: Map<String, Expr>, arg: {t:Type, opt:Bool, name:String}): Expr {
  static function createProperty(classPath: Path, argType: TypeReference, argName: String, typeSchemas: Map<String, Expr>): Expr {
    var schema = lookupSchema(argType, typeSchemas),
        containerType = classPath.asComplexType(),
        type = argType.asComplexType();
    // var schema = lookupSchema(TypeTools.toString(arg.t), map),
    //     field = arg.name,
    //     type = TypeTools.toComplexType(arg.t);
    // // TODO inspect $schema to see if it is an Option, in that case unwrap and use `optional`
    return macro thx.schema.SchemaDSL.required($v{argName}, $schema, function(v : $containerType): $type return Reflect.field(v, $v{argName}));
    // return macro null;
  }
}

typedef FunctionArgument = {
  ctype: Null<ComplexType>,
  opt: Bool,
  name: String
};
