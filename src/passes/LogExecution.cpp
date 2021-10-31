/*
 * Copyright 2017 WebAssembly Community Group participants
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
// Instruments the build with code to log execution at each function
// entry, loop header, and return. This can be useful in debugging, to log out
// a trace, and diff it to another (running in another browser, to
// check for bugs, for example).
//
// The logging is performed by calling an ffi with an id for each
// call site. You need to provide that import on the JS side.
//
// This pass is more effective on flat IR (--flatten) since when it
// instruments say a return, there will be no code run in the return's
// value.
//

#include "asmjs/shared-constants.h"
#include "shared-constants.h"
#include <pass.h>
#include <wasm-builder.h>
#include <wasm.h>

namespace wasm {

Name LOGGER("log_execution");

struct LogExecution : public WalkerPass<PostWalker<LogExecution>> {
  void visitIf(If* curr) {
    curr->ifTrue = makeLogCall(curr->ifTrue);
    if (curr->ifFalse) {
      curr->ifFalse = makeLogCall(curr->ifFalse);
    }
    replaceCurrent(makeLogCall(curr));
  }

  void visitSelect(Select* curr) {
    Builder builder(*getModule());
    curr->condition =
      builder.makeIf(curr->condition,
                     makeLogCall(builder.makeConst(int32_t(1))),
                     makeLogCall(builder.makeConst(int32_t(0))));
  }

  void visitLoop(Loop* curr) { curr->body = makeLogCall(curr->body); }

  void visitBreak(Break* curr) { replaceCurrent(makeLogCall(curr)); }

  void visitReturn(Return* curr) { replaceCurrent(makeLogCall(curr)); }

  void visitFunction(Function* curr) {
    if (curr->imported()) {
      return;
    }
    if (auto* block = curr->body->dynCast<Block>()) {
      if (!block->list.empty()) {
        block->list.back() = makeLogCall(block->list.back());
      }
    }
    curr->body = makeLogCall(curr->body);
  }

  void visitModule(Module* curr) {
    // Add the import
    auto import =
      Builder::makeFunction(LOGGER, Signature(Type::i32, Type::none), {});
    import->module = ENV;
    import->base = LOGGER;
    curr->addFunction(std::move(import));
  }

private:
  Expression* makeLogCall(Expression* curr) {
    static Index id = 0;
    Builder builder(*getModule());
    return builder.makeSequence(
      builder.makeCall(LOGGER, {builder.makeConst(int32_t(id++))}, Type::none),
      curr);
  }
};

Pass* createLogExecutionPass() { return new LogExecution(); }

} // namespace wasm
