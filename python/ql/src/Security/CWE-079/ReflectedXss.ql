/**
 * @name Reflected server-side cross-site scripting
 * @description Writing user input directly to a web page
 *              allows for a cross-site scripting vulnerability.
 * @kind path-problem
 * @problem.severity error
 * @sub-severity high
 * @precision high
 * @id py/reflective-xss
 * @tags security
 *       external/cwe/cwe-079
 *       external/cwe/cwe-116
 */

import python
import semmle.python.security.Paths

/* Sources */
import semmle.python.web.HttpRequest

/* Sinks */

import semmle.python.web.HttpResponse

/* Flow */
import semmle.python.security.strings.Untrusted


class RefectedXssConfiguration extends TaintTracking::Configuration {

    RefectedXssConfiguration() { this = "Reflected XSS configuration" }

    override predicate isSource(TaintTracking::Source source) { source.isSourceOf(any(UntrustedStringKind u)) }

    override predicate isSink(TaintTracking::Sink sink) { sink.sinks(any(UntrustedStringKind u)) }

}

from RefectedXssConfiguration config, TaintedPathSource src, TaintedPathSink sink
where config.hasFlowPath(src, sink)
select sink.getSink(), src, sink, "Cross-site scripting vulnerability due to $@.", src.getSource(), "user-provided value"
