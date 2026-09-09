local source = require("inline-diff.source")

describe("source specifications", function()
  it("normalizes legacy refs and source tables", function()
    assert.are.same({ type = "git", ref = "HEAD" }, source.normalize(nil))
    assert.are.same({ type = "git", ref = "HEAD~1" }, source.normalize("HEAD~1"))
    assert.are.same({ type = "index" }, source.normalize("staged"))
    assert.are.same({ type = "index" }, source.normalize({ type = "index" }))
    assert.are.same({ type = "empty" }, source.normalize({ type = "empty" }))
  end)

  it("uses stable keys for equivalent sources", function()
    assert.are.equal("git:HEAD", source.key("HEAD"))
    assert.are.equal("index", source.key("staged"))
    assert.are.equal("index", source.key({ type = "index" }))
    assert.are.equal("empty", source.key({ type = "empty" }))
  end)
end)

describe("git sources", function()
  local root = vim.fn.getcwd()
  local tracked_file = root .. "/tests/init_spec.lua"
  local missing_file = root .. "/tests/.inline-diff-source-missing"

  local function get(filepath, spec)
    local lines, err
    source.get(filepath, spec, function(result, result_err)
      lines = result
      err = result_err
    end)
    vim.wait(2000, function()
      return lines ~= nil or err ~= nil
    end)
    return lines, err
  end

  it("loads content from a Git ref", function()
    local lines, err = get(tracked_file, "HEAD")
    assert.is_nil(err)
    assert.is_not_nil(lines)
    assert.are.equal('local M = require("inline-diff")', lines[1])
  end)

  it("loads content from the index", function()
    local lines, err = get(tracked_file, "staged")
    assert.is_nil(err)
    assert.is_not_nil(lines)
    assert.are.equal('local M = require("inline-diff")', lines[1])
  end)

  it("uses an empty snapshot for paths missing from a ref", function()
    local lines, err = get(missing_file, "HEAD")
    assert.is_nil(err)
    assert.are.same({}, lines)

    lines, err = get(missing_file, "staged")
    assert.is_nil(err)
    assert.are.same({}, lines)
  end)

  it("reports an invalid Git ref", function()
    local lines, err = get(tracked_file, "does-not-exist")
    assert.is_nil(lines)
    assert.is_truthy(err)
  end)
end)
