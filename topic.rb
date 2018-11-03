require 'natto'
require 'cabocha'

class NattoParser
  attr_accessor :nm

  def initialize()
    @nm = Natto::MeCab.new
  end

  def extractWord(text)
    words = []
    index = 0

    @nm.parse(text) do |n|
      pos = n.feature.split(",")[0]
      if pos == "名詞" and n.posid != 59
        words.push(n.surface)
      end
    end

    return words[rand(words.length)]
  end
end

class CaboChaParser
  attr_accessor :cp

  def initialize()
    @cc = CaboCha::Parser.new
  end

  def parseText(text)
    tree = @cc.parse(text)
    puts tree.toString(CaboCha::FORMAT_TREE)
    return tree
  end
end

n = NattoParser.new

text = STDIN.gets
p n.extractWord(text)


