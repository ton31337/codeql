private import swift

cached
newtype TControlFlowElement =
  TAstElement(AstNode n) or
  TFuncDeclElement(AbstractFunctionDecl func) { func.hasBody() } or
  TPropertyGetterElement(Decl accessor, Expr ref) { isPropertyGetterElement(accessor, ref) } or
  TPropertySetterElement(AccessorDecl accessor, AssignExpr assign) {
    isPropertySetterElement(accessor, assign)
  } or
  TPropertyObserverElement(AccessorDecl observer, AssignExpr assign) {
    isPropertyObserverElement(observer, assign)
  }

predicate isLValue(Expr e) { any(AssignExpr assign).getDest() = e }

predicate isRValue(Expr e) { not isLValue(e) }

predicate ignoreAstElement(AstNode n) {
  isPropertyGetterElement(_, n)
  or
  isPropertySetterElement(_, n)
}

private AccessorDecl getAnAccessorDecl(Decl d) {
  result = d.(VarDecl).getAnAccessorDecl() or
  result = d.(SubscriptDecl).getAnAccessorDecl()
}

predicate isPropertyGetterElement(AccessorDecl accessor, Expr ref) {
  hasDirectToImplementationOrOrdinarySemantics(ref) and
  isRValue(ref) and
  accessor.isGetter() and
  accessor = getAnAccessorDecl([ref.(LookupExpr).getMember(), ref.(DeclRefExpr).getDecl()])
}

predicate isPropertyGetterElement(PropertyGetterElement pge, AccessorDecl accessor, Expr ref) {
  pge = TPropertyGetterElement(accessor, ref)
}

private predicate hasDirectToImplementationSemantics(Expr e) {
  e.(MemberRefExpr).hasDirectToImplementationSemantics()
  or
  e.(SubscriptExpr).hasDirectToImplementationSemantics()
  or
  e.(DeclRefExpr).hasDirectToImplementationSemantics()
}

private predicate hasOrdinarySemantics(Expr e) {
  e.(MemberRefExpr).hasOrdinarySemantics()
  or
  e.(SubscriptExpr).hasOrdinarySemantics()
  or
  e.(DeclRefExpr).hasOrdinarySemantics()
}

private predicate hasDirectToImplementationOrOrdinarySemantics(Expr e) {
  hasDirectToImplementationSemantics(e) or hasOrdinarySemantics(e)
}

private predicate isPropertySetterElement(AccessorDecl accessor, AssignExpr assign) {
  exists(Expr lhs | lhs = assign.getDest() |
    hasDirectToImplementationOrOrdinarySemantics(lhs) and
    accessor.isSetter() and
    isLValue(lhs) and
    accessor = getAnAccessorDecl([lhs.(LookupExpr).getMember(), lhs.(DeclRefExpr).getDecl()])
  )
}

predicate isPropertySetterElement(
  PropertySetterElement pse, AccessorDecl accessor, AssignExpr assign
) {
  pse = TPropertySetterElement(accessor, assign)
}

private predicate isPropertyObserverElement(AccessorDecl observer, AssignExpr assign) {
  exists(Expr lhs | lhs = assign.getDest() |
    hasDirectToImplementationOrOrdinarySemantics(lhs) and
    observer.isPropertyObserver() and
    isLValue(lhs) and
    observer = getAnAccessorDecl([lhs.(LookupExpr).getMember(), lhs.(DeclRefExpr).getDecl()])
  )
}

predicate isPropertyObserverElement(
  PropertyObserverElement poe, AccessorDecl accessor, AssignExpr assign
) {
  poe = TPropertyObserverElement(accessor, assign)
}

class ControlFlowElement extends TControlFlowElement {
  string toString() { none() } // overriden in subclasses

  AstNode asAstNode() { none() }

  Location getLocation() { none() } // overriden in subclasses
}

class AstElement extends ControlFlowElement, TAstElement {
  AstNode n;

  AstElement() { this = TAstElement(n) }

  override string toString() { result = n.toString() }

  override AstNode asAstNode() { result = n }

  override Location getLocation() { result = n.getLocation() }
}

class PropertyGetterElement extends ControlFlowElement, TPropertyGetterElement {
  AccessorDecl accessor;
  Expr ref;

  PropertyGetterElement() { this = TPropertyGetterElement(accessor, ref) }

  override string toString() { result = "getter for " + ref.toString() }

  override Location getLocation() { result = ref.getLocation() }

  Expr getRef() { result = ref }

  AccessorDecl getAccessorDecl() { result = accessor }
}

class PropertySetterElement extends ControlFlowElement, TPropertySetterElement {
  AccessorDecl accessor;
  AssignExpr assign;

  PropertySetterElement() { this = TPropertySetterElement(accessor, assign) }

  override string toString() { result = "setter for " + assign }

  override Location getLocation() { result = assign.getLocation() }

  AccessorDecl getAccessorDecl() { result = accessor }

  AssignExpr getAssignExpr() { result = assign }
}

class PropertyObserverElement extends ControlFlowElement, TPropertyObserverElement {
  AccessorDecl observer;
  AssignExpr assign;

  PropertyObserverElement() { this = TPropertyObserverElement(observer, assign) }

  override string toString() {
    this.isWillSet() and
    result = "willSet observer for " + assign.toString()
    or
    this.isDidSet() and
    result = "didSet observer for " + assign.toString()
  }

  override Location getLocation() { result = assign.getLocation() }

  AccessorDecl getObserver() { result = observer }

  predicate isWillSet() { observer.isWillSet() }

  predicate isDidSet() { observer.isDidSet() }

  AssignExpr getAssignExpr() { result = assign }
}

class FuncDeclElement extends ControlFlowElement, TFuncDeclElement {
  AbstractFunctionDecl func;

  FuncDeclElement() { this = TFuncDeclElement(func) }

  override string toString() { result = func.toString() }

  override Location getLocation() { result = func.getLocation() }
}
