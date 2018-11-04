require 'natto'
require 'json'
require 'mongo'

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

class Markov
  public
    def genMarkovBlock(words)
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

def tweet2textdata(text)
  replypattern = /@[\w]+/

  text = text.gsub(replypattern, '')

  textURI = URI.extract(text)

  for uri in textURI do
    text = text.gsub(uri, '')
  end 

  return text
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

def makeDataBase()
  n = NattoParser.new
  m = Markov.new

  client = Mongo::Client.new('mongodb://localhost/hsm_ai')
  coll = client[:blocks]

  monthlytweets= []
  Dir.glob("data/*") do |f|
    monthlytweets.push(get_tweets_from_JSON(f))
  end

  parsedtweet = []
  monthlytweets.each_with_index do |tweets, i|
    parsedtweet.push(n.parseTextArray(tweets))
  end
    
  parsedtweet = reduce_degree(parsedtweet)

  parsedtweet.each do |p|
    m.genMarkovBlock(p).each do |b|
      coll.insert_one({block: b})
    end
  end

  p coll.find_one
end

makeDataBase()
