/**
 * Provides classes modeling security-relevant aspects of the `invoke` PyPI package.
 * See https://www.pyinvoke.org/.
 */

private import python
private import experimental.dataflow.DataFlow
private import experimental.semmle.python.Concepts

/**
 * Provides models for the `invoke` PyPI package.
 * See https://www.pyinvoke.org/.
 */
private module Invoke {
  // ---------------------------------------------------------------------------
  // invoke
  // ---------------------------------------------------------------------------
  /** Gets a reference to the `invoke` module. */
  private DataFlow::Node invoke(DataFlow::TypeTracker t) {
    t.start() and
    result = DataFlow::importModule("invoke")
    or
    exists(DataFlow::TypeTracker t2 | result = invoke(t2).track(t2, t))
  }

  /** Gets a reference to the `invoke` module. */
  DataFlow::Node invoke() { result = invoke(DataFlow::TypeTracker::end()) }

  /**
   * Gets a reference to the attribute `attr_name` of the `invoke` module.
   * WARNING: Only holds for a few predefined attributes.
   */
  private DataFlow::Node invoke_attr(DataFlow::TypeTracker t, string attr_name) {
    attr_name in ["run", "sudo", "context", "Context"] and
    (
      t.start() and
      result = DataFlow::importMember("invoke", attr_name)
      or
      t.startInAttr(attr_name) and
      result = DataFlow::importModule("invoke")
    )
    or
    // Due to bad performance when using normal setup with `invoke_attr(t2, attr_name).track(t2, t)`
    // we have inlined that code and forced a join
    exists(DataFlow::TypeTracker t2 |
      exists(DataFlow::StepSummary summary |
        invoke_attr_first_join(t2, attr_name, result, summary) and
        t = t2.append(summary)
      )
    )
  }

  pragma[nomagic]
  private predicate invoke_attr_first_join(
    DataFlow::TypeTracker t2, string attr_name, DataFlow::Node res, DataFlow::StepSummary summary
  ) {
    DataFlow::StepSummary::step(invoke_attr(t2, attr_name), res, summary)
  }

  /**
   * Gets a reference to the attribute `attr_name` of the `invoke` module.
   * WARNING: Only holds for a few predefined attributes.
   */
  private DataFlow::Node invoke_attr(string attr_name) {
    result = invoke_attr(DataFlow::TypeTracker::end(), attr_name)
  }

  /** Provides models for the `invoke` module. */
  module invoke {
    /** Gets a reference to the `invoke.context` module. */
    DataFlow::Node context() { result = invoke_attr("context") }

    /** Provides models for the `invoke.context` module */
    module context {
      /** Provides models for the `invoke.context.Context` class */
      module Context {
        /** Gets a reference to the `invoke.context.Context` class. */
        private DataFlow::Node class_(DataFlow::TypeTracker t) {
          t.start() and
          result = DataFlow::importMember("invoke.context", "Context")
          or
          t.startInAttr("Context") and
          result = invoke::context()
          or
          t.start() and
          result = invoke_attr("Context")
          or
          exists(DataFlow::TypeTracker t2 | result = class_(t2).track(t2, t))
        }

        /** Gets a reference to the `invoke.context.Context` class. */
        DataFlow::Node class_() { result = class_(DataFlow::TypeTracker::end()) }

        /** Gets a reference to an instance of `invoke.context.Context`. */
        private DataFlow::Node instance(DataFlow::TypeTracker t) {
          t.start() and
          result.asCfgNode().(CallNode).getFunction() =
            invoke::context::Context::class_().asCfgNode()
          or
          exists(DataFlow::TypeTracker t2 | result = instance(t2).track(t2, t))
        }

        /** Gets a reference to an instance of `invoke.context.Context`. */
        DataFlow::Node instance() { result = instance(DataFlow::TypeTracker::end()) }

        /** Gets a reference to the `run` or `sudo` methods on a `invoke.context.Context` instance. */
        private DataFlow::Node instanceRunMethods(DataFlow::TypeTracker t) {
          t.startInAttr(["run", "sudo"]) and
          result = invoke::context::Context::instance()
          or
          exists(DataFlow::TypeTracker t2 | result = instanceRunMethods(t2).track(t2, t))
        }

        /** Gets a reference to the `run` or `sudo` methods on a `invoke.context.Context` instance. */
        DataFlow::Node instanceRunMethods() {
          result = instanceRunMethods(DataFlow::TypeTracker::end())
        }
      }
    }
  }

  /**
   * A call to either
   * - `invoke.run` or `invoke.sudo` functions (http://docs.pyinvoke.org/en/stable/api/__init__.html)
   * - `run` or `sudo` methods on a `invoke.context.Context` instance (http://docs.pyinvoke.org/en/stable/api/context.html#invoke.context.Context.run)
   */
  private class InvokeRunCommandCall extends SystemCommandExecution::Range {
    InvokeRunCommandCall() {
      exists(DataFlow::Node callFunction |
        this.asCfgNode().(CallNode).getFunction() = callFunction.asCfgNode()
      |
        callFunction = invoke_attr(["run", "sudo"])
        or
        callFunction = invoke::context::Context::instanceRunMethods()
      )
    }

    override DataFlow::Node getCommand() {
      result.asCfgNode() = this.asCfgNode().(CallNode).getArg(0)
      or
      result.asCfgNode() = this.asCfgNode().(CallNode).getArgByName("command")
    }
  }
}
