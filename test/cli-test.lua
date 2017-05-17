---- -*- Mode: Lua; -*-                                                                           
----
---- cli-test.lua      sniff test for the CLI
----
---- © Copyright IBM Corporation 2016, 2017.
---- LICENSE: MIT License (https://opensource.org/licenses/mit-license.html)
---- AUTHOR: Jamie A. Jennings

test.start(test.current_filename())

-- These tests are designed to run in the Rosie development environment, which is entered with: bin/rosie -D
assert(ROSIE_HOME, "ROSIE_HOME is not set?")
assert(type(rosie)=="table", "rosie package not loaded as 'rosie'?")
import = rosie._env.import
if not test then
   test = import("test")
end

list = import("list")
util = import "util"
check = test.check

rosie_cmd = ROSIE_HOME .. "/bin/rosie"
local try = io.open(rosie_cmd, "r")
if try then
   try:close()					    -- found it.  will use it.
else
   local tbl, status, code = util.os_execute_capture("which rosie")
   if code==0 and tbl and tbl[1] and type(tbl[1])=="string" then
      rosie_cmd = tbl[1]:sub(1,-2)			    -- remove lf at end
   else
      error("Cannot find rosie executable")
   end
end
print("Found rosie executable: " .. rosie_cmd)

infilename = "/tmp/rosietestinputfile"

input = [[
#
# This file is automatically generated on OSX.
#
search nc.rr.com
nameserver 10.0.1.1
nameserver 2606:a000:1120:8152:2f7:6fff:fed4:dc1f
/usr/share/bin/foo
jjennings@us.ibm.com
]]

f, msg = io.open(infilename, "w")
if (not f) then
   error("Could not create the input file for this test: " .. tostring(msg))
end
f:write(input)
f:close()

print("Input file (" .. infilename .. ") created successfully")

function run(import, expression, grep_flag, expectations)
   test.heading(expression)
   test.subheading((grep_flag and "Using grep command") or "Using match command")
   local verb = (grep_flag and "Grepping for") or "Matching"
   print("\nSTART ----------------- " .. verb .. " '" .. expression .. "' against fixed input -----------------")
   local import_option = ""
   if import then import_option = " --rpl '" .. import .. "' "; end
   local cmd = rosie_cmd .. import_option ..
      (grep_flag and " grep" or " match") .. " '" .. expression .. "' " .. infilename
   print(cmd)
   local results, status, code = util.os_execute_capture(cmd, nil, "l")
   if not results then error("Run failed: " .. tostring(status) .. ", " .. tostring(code)); end
   local mismatch_flag = false;
   if expectations then
      for i=1, #expectations do 
	 print(results[i])
	 if expectations then
	    if results[i]~=expectations[i] then print("Mismatch"); mismatch_flag = true; end
	 end
      end -- for
      if mismatch_flag then
	 print("********** SOME MISMATCHED OUTPUT WAS FOUND. **********");
      else
	 print("END ----------------- All output matched expectations. -----------------");
      end
      if (not (#results==#expectations)) then
	 print(string.format("********** Mismatched number of results (%d) versus expectations (%d) **********", #results, #expectations))
      end
      check((not mismatch_flag), "Mismatched output compared to expectations", 1)
      check((#results==#expectations), "Mismatched number of results compared to expectations", 1)
   end -- if expectations
   return results
end

---------------------------------------------------------------------------------------------------
test.heading("Match and grep commands")
---------------------------------------------------------------------------------------------------

results_basic_matchall = 
   {"\27[30m#\27[0m ",
    "\27[30m#\27[0m \27[33mThis\27[0m \27[33mfile\27[0m \27[33mis\27[0m \27[33mautomatically\27[0m \27[33mgenerated\27[0m \27[33mon\27[0m \27[36mOSX\27[0m \27[30m.\27[0m ",
    "\27[30m#\27[0m ",
    "\27[33msearch\27[0m \27[31mnc.rr.com\27[0m ",
    "\27[33mnameserver\27[0m \27[31m10.0.1.1\27[0m ",
    "\27[33mnameserver\27[0m \27[4m2606\27[0m \27[30m:\27[0m \27[4ma000\27[0m \27[30m:\27[0m \27[4m1120\27[0m \27[30m:\27[0m \27[4m8152\27[0m \27[30m:\27[0m \27[4m2f7\27[0m \27[30m:\27[0m \27[4m6fff\27[0m \27[30m:\27[0m \27[4mfed4\27[0m \27[30m:\27[0m \27[4mdc1f\27[0m ",
    "\27[32m/usr/share/bin/foo\27[0m ",
    "\27[31mjjennings@us.ibm.com\27[0m "}

results_common_word =
   {"\27[33msearch\27[0m ",
    "\27[33mnameserver\27[0m ",
    "\27[33mnameserver\27[0m ",
    "\27[33mjjennings\27[0m "}

results_common_word_grep = 
   {"# This file is automatically generated on OSX.",
    "search nc.rr.com",
    "nameserver 10.0.1.1",
    "nameserver 2606:a000:1120:8152:2f7:6fff:fed4:dc1f",
    "/usr/share/bin/foo",
    "jjennings@us.ibm.com"
 }

results_word_network = 
   {"[33msearch[0m [30mnc.rr.com[0m ",
    "[33mnameserver[0m [30m10.0.1.1[0m ",
    "[33mnameserver[0m [30m2606[0m [30ma000[0m [30m1120[0m [30m8152[0m [30m2f7[0m [30m6fff[0m [30mfed4[0m [30mdc1f[0m "}

--   {"\27[33msearch\27[0m \27[31mnc.rr.com\27[0m ",
--    "\27[33mnameserver\27[0m \27[31m10.0.1.1\27[0m "}

results_common_number =
   {"nameserver 10.0.1.1",
    "nameserver 2606:a000:1120:8152:2f7:6fff:fed4:dc1f"}




-- FIXME: add basic.matchall back in when we have the equivalent pattern written for rpl 1.1
--run("basic.matchall", nil, results_basic_matchall)

-- FIXME: re-enable the grep test cases
run("import common", "common.word", nil, results_common_word)
--run("import common", "common.word", true, results_common_word_grep)
run("import common, net", "common.word net.any", nil, results_word_network)
--run("import common", "~common.number~", true, results_common_number)

ok, msg = pcall(run, "import common", "foo = common.word", nil, nil)
check(ok)
check(msg[1]:find("syntax error"))

--ok, msg = pcall(run, "import common", "foo = common.word", true, nil)
--check(ok)
--check(msg[1]:find("syntax error"))

ok, msg = pcall(run, "import common", "/foo/", nil, nil)
check(ok)
check(msg[1]:find("syntax error"))

ok, ignore = pcall(run, "import common", '"Gold"', nil, nil)
check(ok, [[testing for a shell quoting error in which rpl expressions containing double quotes
      were not properly passed to lua in bin/run-rosie]])

print("\nChecking that the command line expression can contain [[...]] per Issue #22")
cmd = rosie_cmd .. " list --rpl 'lua_ident = {[[:alpha:]] / \"_\" / \".\" / \":\"}+'"
print(cmd)
results, status, code = util.os_execute_capture(cmd, nil)
check(results, "Expression on command line can contain [[.,.]]") -- command succeeded
check(code==0, "Return code is zero")
check(results[#results]:sub(-9):find("patterns")==1)

---------------------------------------------------------------------------------------------------
test.heading("Test command")

print("\nSniff test of the lightweight test facility (MORE TESTS LIKE THIS ARE NEEDED)")
-- Passing tests
cmd = rosie_cmd .. " test " .. ROSIE_HOME .. "/test/lightweight-test-pass.rpl"
print(cmd)
results, status, code = util.os_execute_capture(cmd, nil)
check(results)
check(code==0, "Return code is zero")
check(results[#results]:find("All tests passed"))
-- Failing tests
cmd = rosie_cmd .. " test " .. ROSIE_HOME .. "/test/lightweight-test-fail.rpl"
print(cmd)
results, status, code = util.os_execute_capture(cmd, nil)
check(results)
check(type(results[1])=="string")
check(code~=0, "Return code not zero")
-- The last two output lines explain the test failures in our sample input file
local function split(s, sep)
   sep = lpeg.P(sep)
   local elem = lpeg.C((1 - sep)^0)
   local p = lpeg.Ct(elem * (sep * elem)^0)
   return lpeg.match(p, s)
end
lines = split(results[1], "\n")
check(lines[#lines]=="")
check(lines[#lines-1]:find("FAIL"))
check(lines[#lines-2]:find("FAIL"))

---------------------------------------------------------------------------------------------------
test.heading("Info command")

cmd = rosie_cmd .. " info"
print(); print(cmd)
results, status, code = util.os_execute_capture(cmd, nil)
check(results, "info command succeeded")
check(code==0, "Return code is zero")
-- check for a few of the items displayed by the info command
check(results[1]:find("ROSIE_HOME"))      
check(results[1]:find("ROSIE_VERSION"))      
check(results[1]:find("ROSIE_COMMAND"))      
check(results[1]:find("BUILD_DATE"))      
check(results[1]:find("GIT_BRANCH"))      
check(results[1]:find("GIT_COMMIT"))      

---------------------------------------------------------------------------------------------------
test.heading("Help command")

cmd = rosie_cmd .. " help"
print(); print(cmd)
results, status, code = util.os_execute_capture(cmd, nil)
check(results, "command succeeded")
check(code==0, "Return code is zero")
check(results[1]:find("Usage:"))
check(results[1]:find("Options:"))
check(results[1]:find("Commands:"))


return test.finish()
