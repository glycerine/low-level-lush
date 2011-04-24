package com.richhickey.jfli;

//    Copyright (c) Rich Hickey. All rights reserved.
//    The use and distribution terms for this software are covered by the
//    Common Public License 1.0 (http://opensource.org/licenses/cpl.php)
//    which can be found in the file CPL.TXT at the root of this distribution.
//    By using this software in any fashion, you are agreeing to be bound by
//    the terms of this license.
//    You must not remove this notice, or any other, from this software.

import java.lang.*;
import java.lang.reflect.*;

public class LispInvocationHandler implements InvocationHandler
{
public native Object invoke(Object proxy,Method method, Object[] args) throws Throwable;
}
