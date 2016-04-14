package thx.schema;

import haxe.ds.Option;

import thx.Functions.identity;
import thx.fp.Functions.flip;

using thx.Arrays;
using thx.Functions;
using thx.Options;

import thx.schema.Schema;

/**
 * A couple of useful interpreters for Schema values. This class is intended
 * to be imported via 'using'.
 */
class SchemaExtensions {
  public static function id<A>(a: Alternative<A>)
    return switch a {
      case Prism(id, _, _, _): id;
    };
}

class ObjectSchemaExtensions {
  public static function contramap<N, O, A>(o: ObjectBuilder<O, A>, f: N -> O): ObjectBuilder<N, A> {
    return switch o {
      case Pure(a): Pure(a);
      case Ap(s, k): Ap(contramapPS(s, f), contramap(k, f));
    }
  }

  public static function map<O, A, B>(s: ObjectBuilder<O, A>, f: A -> B): ObjectBuilder<O, B> {
    // helper function used to unpack existential type I
    inline function go<I>(s: PropSchema<O, I>, k: ObjectBuilder<O, I -> A>): ObjectBuilder<O, B> {
      return Ap(s, map(k, f.compose));
    }

    return switch s {
      case Pure(a): Pure(f(a));
      case Ap(s, k): go(s, k);
    };
  }

  public static function ap<O, A, B>(s: ObjectBuilder<O, A>, f: ObjectBuilder<O, A -> B>): ObjectBuilder<O, B> {
    // helper function used to unpack existential type I
    inline function go<I>(si: PropSchema<O, I>, ki: ObjectBuilder<O, I -> (A -> B)>): ObjectBuilder<O, B> {
      return Ap(si, ap(s, map(ki, flip)));
    }

    return switch f {
      case Pure(g): map(s, g);
      case Ap(fs, fk): go(fs, fk);
    };
  }

  public static function contramapPS<N, O, A>(s: PropSchema<O, A>, f: N -> O): PropSchema<N, A>
    return switch s {
      case Required(n, s, a): Required(n, s, a.compose(f));
      case Optional(n, s, a): Optional(n, s, a.compose(f));
    };
}
