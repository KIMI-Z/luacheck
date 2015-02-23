local utils = require "luacheck.utils"

describe("utils", function()
   describe("read_file", function()
      it("returns contents of a file", function()
         assert.equal("contents\n", utils.read_file("spec/folder/foo"))
      end)

      it("returns nil for non-existent paths", function()
         assert.is_nil(utils.read_file("spec/folder/non-existent"))
      end)
   end)

   describe("load_config", function()
      it("loads config from a file and returns it", function()
         assert.same({foo = "bar"}, utils.load_config("spec/folder/config"))
      end)

      it("passes second argument as environment", function()
         local function bar() return "bar" end
         assert.same({
            foo = "bar",
            bar = bar
         }, utils.load_config("spec/folder/env_config", {bar = bar}))
      end)

      it("returns nil, \"I/O\" for non-existent paths", function()
         local ok, err = utils.load_config("spec/folder/non-existent")
         assert.is_nil(ok)
         assert.equal("I/O", err)
      end)

      it("returns nil, \"syntax\" for configs with syntax errors", function()
         local ok, err = utils.load_config("spec/folder/bad_config")
         assert.is_nil(ok)
         assert.equal("syntax", err)
      end)

      it("returns nil, \"syntax\" for configs with run-time errors", function()
         local ok, err = utils.load_config("spec/folder/env_config")
         assert.is_nil(ok)
         assert.equal("syntax", err)
      end)
   end)

   describe("array_to_set", function()
      it("converts array to set and returns it", function()
         assert.same({foo = 3, bar = 2}, utils.array_to_set({"foo", "bar", "foo"}))
      end)
   end)

   describe("concat_arrays", function()
      it("returns concatenated arrays", function()
         assert.same({1, 2, 3, 4}, utils.concat_arrays({{}, {1}, {2, 3, 4}, {}}))
      end)
   end)

   describe("update", function()
      it("updates first table with entries from second", function()
         local t1 = {k1 = 1, k2 = 2}
         local t2 = {k2 = 3, k3 = 4}
         utils.update(t1, t2)
         assert.same({k1 = 1, k2 = 3, k3 = 4}, t1)
      end)
   end)
end)
