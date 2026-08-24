"""A Sphinx domain for Typst, so that this package's own functions can be documented as objects
rather than as sections.

An object gets a signature, a set of argument fields and a cross-reference target, which is what
lets one page write ``:any:`sync``` and land on the definition wherever it lives.  There is no such
domain on PyPI -- `sphinx-typst`, `sphinxcontrib-typst`, `typst-domain` and `sphinx-typst-domain`
are all unclaimed -- and Sphinx's own Python domain is no substitute: it parses signatures as
Python, and `lamport-diagram` is not a Python identifier.

Three kinds of object, because the library has three kinds of name:

- a **function** is called -- ``sync(name, ..args)``;
- a **value** is passed -- ``horizontal``, ``above``, ``default-palette``;
- an **argument** is the name a value is passed under -- ``orientation``, ``overlays``;
- a **locator** entry is one of the keys a drawing is handed inside ``overlays``.
"""

from docutils import nodes
from sphinx import addnodes
from sphinx.addnodes import (
    desc_annotation,
    desc_name,
    desc_parameter,
    desc_parameterlist,
)
from sphinx.directives import ObjectDescription
from sphinx.domains import Domain, ObjType
from sphinx.roles import XRefRole
from sphinx.util.docfields import Field, GroupedField, TypedField
from sphinx.util.nodes import make_refnode


class TypstParamXRefRole(XRefRole):
    """`caption`:param: -- an argument of the object the reference is written inside."""

    def process_link(self, env, refnode, has_explicit_title, title, target):
        refnode["typst:object"] = env.ref_context.get("typst:object")
        if not has_explicit_title:
            title = target.split(".")[-1]
        return title, target


class TypstObject(ObjectDescription):
    """One documented name: its signature line, its fields and its anchor."""

    #: What the index and the signature call this kind of object.  Subclasses set it.
    kind = "object"

    doc_field_types = [
        TypedField(
            "argument",
            label="Arguments",
            names=("param", "arg", "argument"),
            typenames=("type", "paramtype"),
            typerolename="obj",
            can_collapse=True,
        ),
        GroupedField("default", label="Defaults", names=("default",), can_collapse=True),
        Field("returns", label="Returns", has_arg=False, names=("returns", "return")),
    ]

    def handle_signature(self, sig, signode):
        """Split ``name(arg, arg)`` into the name, which is addressable, and its arguments, which
        become a parameter list -- so that a signature too long for one line is broken across
        several by `maximum_signature_line_length` rather than running off the page."""
        name, _, rest = sig.partition("(")
        name = name.strip()
        signode["fullname"] = name
        signode += desc_name(name, name)
        if rest:
            params = desc_parameterlist()
            depth, current = 0, ""
            for char in rest.rstrip().removesuffix(")"):
                if char in "([{":
                    depth += 1
                elif char in ")]}":
                    depth -= 1
                if char == "," and depth == 0:
                    params += desc_parameter(current.strip(), current.strip())
                    current = ""
                else:
                    current += char
            if current.strip():
                params += desc_parameter(current.strip(), current.strip())
            signode += params
        if self.kind != "function":
            signode += desc_annotation(" ", f" ({self.kind})")
        return name

    def _object_hierarchy_parts(self, sig_node):
        name = sig_node.get("fullname")
        return (name,) if name else ()

    def _toc_entry_name(self, sig_node):
        """What the sidebar calls this object.  A function is shown as a call, so that a reader
        scanning the contents can tell one from an argument at a glance."""
        if not sig_node.get("_toc_parts"):
            return ""
        name = sig_node["_toc_parts"][-1]
        return f"{name}()" if self.kind == "function" else name

    def before_content(self):
        """Remember the object being described, so that a `:param:` in its body needs no prefix."""
        if self.names:
            self.env.ref_context["typst:object"] = self.names[-1]

    def after_content(self):
        self.env.ref_context.pop("typst:object", None)

    def add_target_and_index(self, name, sig, signode):
        node_id = f"typst-{self.kind}-{name}"
        signode["ids"].append(node_id)
        self.env.get_domain("typst").note_object(self.kind, name, node_id)
        self.indexnode["entries"].append(
            ("single", f"{name} (Typst {self.kind})", node_id, "", None)
        )


class TypstFunction(TypstObject):
    kind = "function"


class TypstValue(TypstObject):
    kind = "value"


class TypstArgument(TypstObject):
    kind = "argument"


class TypstLocator(TypstObject):
    kind = "locator"


class TypstDomain(Domain):
    name = "typst"
    label = "Typst"

    object_types = {
        "function": ObjType("function", "func", "obj"),
        "value": ObjType("value", "value", "obj"),
        "argument": ObjType("argument", "arg", "obj"),
        "locator": ObjType("locator", "locator", "obj"),
    }
    directives = {
        "function": TypstFunction,
        "value": TypstValue,
        "argument": TypstArgument,
        "locator": TypstLocator,
    }
    roles = {
        "func": XRefRole(),
        "value": XRefRole(),
        "arg": XRefRole(),
        "param": TypstParamXRefRole(),
        "locator": XRefRole(),
        "obj": XRefRole(),
    }
    initial_data = {"objects": {}, "parameters": {}}

    @property
    def objects(self):
        return self.data.setdefault("objects", {})

    @property
    def parameters(self):
        return self.data.setdefault("parameters", {})

    def note_parameter(self, owner, param, node_id, docname):
        self.parameters[f"{owner}.{param}"] = (docname, node_id)

    #: A name is unique only within its kind: `orientation` is both an argument of
    #: `lamport-diagram` and an entry of the locator, and the two are different things in different
    #: places.  Keying by both is what lets `orientation`:arg: and `orientation`:locator: part.
    ROLE_KIND = {"func": "function", "value": "value", "arg": "argument", "locator": "locator"}

    def note_object(self, kind, name, node_id):
        self.objects[kind, name] = (self.env.docname, node_id)

    def clear_doc(self, docname):
        for key, (doc, _) in list(self.objects.items()):
            if doc == docname:
                del self.objects[key]
        for name, (doc, _) in list(self.parameters.items()):
            if doc == docname:
                del self.parameters[name]

    def merge_domaindata(self, docnames, otherdata):
        for key, entry in otherdata["objects"].items():
            if entry[0] in docnames:
                self.objects[key] = entry

    def resolve_xref(self, env, fromdocname, builder, typ, target, node, contnode):
        if typ == "param":
            # A bare name means the argument of the object the reference sits in; a dotted one names
            # its object outright, which is what lets another page point at it.
            owner = node.get("typst:object")
            key = target if "." in target else f"{owner}.{target}"
            entry = self.parameters.get(key)
            if entry is None:
                return None
            docname, node_id = entry
            return make_refnode(builder, fromdocname, docname, node_id, contnode, key)
        for kind in ([self.ROLE_KIND[typ]] if typ in self.ROLE_KIND else self.object_types):
            entry = self.objects.get((kind, target))
            if entry is not None:
                docname, node_id = entry
                return make_refnode(builder, fromdocname, docname, node_id, contnode, target)
        return None

    def resolve_any_xref(self, env, fromdocname, builder, target, node, contnode):
        """What makes ``:any:`sync``` work, which `add_object_type` never does.  Every kind that
        answers to the name is returned, so a name meaning two things is reported as ambiguous
        rather than silently resolved to whichever was read first."""
        found = []
        for kind in self.object_types:
            entry = self.objects.get((kind, target))
            if entry is None:
                continue
            docname, node_id = entry
            ref = make_refnode(builder, fromdocname, docname, node_id, contnode, target)
            found.append((f"typst:{self.object_types[kind].roles[0]}", ref))
        return found

    def get_objects(self):
        """What the search index and the general index are built from."""
        for (kind, name), (docname, node_id) in self.objects.items():
            yield name, name, kind, docname, node_id, 1


def note_parameters(app, doctree):
    """Give every documented argument an anchor of its own, and register it under `object.argument`.

    `DocFieldTransformer` rebuilds a field list into grouped fields, so an id put on the raw field
    would not survive; this runs afterwards, over what the reader will actually see.
    """
    domain = app.env.get_domain("typst")
    for desc in doctree.findall(addnodes.desc):
        if desc.get("domain") != "typst":
            continue
        names = [sig["ids"][0] for sig in desc.findall(addnodes.desc_signature) if sig.get("ids")]
        if not names:
            continue
        owner = names[0].split("-", 2)[-1]
        for field in desc.findall(nodes.field):
            for item in field.findall(nodes.list_item):
                strong = next(item.findall(addnodes.literal_strong), None)
                if strong is None:
                    continue
                param = strong.astext().strip()
                node_id = f"typst-param-{owner}-{param}"
                if node_id not in item["ids"]:
                    item["ids"].append(node_id)
                domain.note_parameter(owner, param, node_id, app.env.docname)


def setup(app):
    app.add_domain(TypstDomain)
    app.connect("doctree-read", note_parameters)
    return {"version": "0.1", "parallel_read_safe": True, "parallel_write_safe": True}
