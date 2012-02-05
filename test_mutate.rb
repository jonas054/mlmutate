require 'test/unit'
load 'mutate'

class TestMutate < Test::Unit::TestCase
  def test_chunkify
    assert_equal(["if (", "aa", ">", "0", ")", "if (", "b", ">", "0", ")", ";"],
                 FileMutator.chunkify('if (aa>0)if (b>0);'))

    assert_equal(["return true", ";"], FileMutator.chunkify('return true;'))
  end
end

