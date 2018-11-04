require 'natto'
require 'twitter'

class BlockNotFoundError < StandardError; end

class NattoParser
  attr_accessor :nm
  
  def initialize()
    @nm = Natto::MeCab.new
  end
  
  def parseTextArray(texts)
    words = []
    index = 0
    breakcount = 0

    texts.length.times do |i|
      words.push([])
      @nm.parse(texts[i]) do |n|
        if n.surface != ""
          words[index].push([n.surface, n.posid])
        end
      end
      index += 1
    end

    return words
  end
end

class Marcov
  public
    def genMarcovBlock(words)
      array = []

      # 最初と最後は-1にする
      words.unshift(-1)
      words.push(-1)

      # 3単語ずつ配列に格納
      for i in 0..words.length-3
        array.push([words[i], words[i+1], words[i+2]])
      end

      return array
    end
end

# ===================================================
# 汎用関数
# ===================================================
def generate_text_from_json(keyword, dir)
  parser = NattoParser.new
  marcov = Marcov.new

  block = []

  tweet = ""
  
  if dir != ""
    tweets = get_tweets_from_JSON(dir)
  else
    tweets = []
    Dir.glob("data/*"){ |f|
      tweets.push(get_tweets_from_JSON(f))
    }
    tweets = reduce_degree(tweets)
  end

  words = parser.parseTextArray(tweets)

  # 3単語ブロックをツイートごとの配列に格納
  for word in words
    block.push(marcov.genMarcovBlock(word))
  end

  block = reduce_degree(block)

  # 140字に収まる文章が練成できるまでマルコフ連鎖する
  while tweet.length == 0 or tweet.length > 140 do
    begin
      tweetwords = marcov.marcov(block, keyword)
      if tweetwords == -1
        raise RuntimeError
      end
    rescue RuntimeError
      retry
    end
    tweet = words2str(tweetwords)
  end
  
  return tweet
end

def get_tweets_from_JSON(filename)
  data = nil

  File.open(filename) do |f|
    data = JSON.load(f)
  end

  tweets = []

  for d in data do
    if d["user"]["screen_name"] == "hsm_hx"
      if d["retweeted_status"] == nil
        tweets.push(tweet2textdata(d["text"]))
      end
    end
  end

  return tweets
end

def words2str(words)
  if words.kind_of?(String)
    return words
  end

  str = ""
  for word in words do
    if word != -1
      str += word[0]
    end
  end
  return str
end

def reduce_degree(array)
  result = []

  array.each do |a|
    a.each do |v|
      result.push(v)
    end
  end
  
  return result
end

def tweet2textdata(text)
  replypattern = /@[\w]+/

  text = text.gsub(replypattern, '')

  textURI = URI.extract(text)

  for uri in textURI do
    text = text.gsub(uri, '')
  end 

  return text
end

def main()
  n = NattoParser.new

  monthlytweets= []
  Dir.glob("data/*") do |f|
    monthlytweets.push(get_tweets_from_JSON(f))
  end

  parsedtweet = []
  monthlytweets.each_with_index do |tweets, i|
    p "============= #{i} ============"
    parsedtweet.push(n.parseTextArray(tweets))
  end
end

main()
