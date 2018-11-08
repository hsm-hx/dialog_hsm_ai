require 'mongo'

client = Mongo::Client.new("mongodb://localhost/hsm_ai")
$col = client[:blocks]

class BlockNotFoundError < StandardError; end

class Markov
  public
    def markov(keyword)
      result = []

      begin
        block = findBlocks(keyword)
        if block == -1
          raise RuntimeError
        end
        if block == []
          raise BlockNotFoundError
        end
        result = connectBlockBack(block, result, true)
      rescue RuntimeError
        retry
      rescue BlockNotFoundError
        return "えー、それはなに"
      end

      # resultの最後の単語が-1になるまで繰り返す
      while result[result.length-1] != -1 do
        result = connectBlockBack(
          findBlocksBack(result[result.length-1]), 
          result
        )
      end

      while result[0] != -1 do
        result = connectBlockFront(
          findBlocksFront(result[0]), 
          result
        )
      end

      return result
    end

    def genmarkovBlock(words)
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

  private
    def findBlocksFront(target)
      blocks = []

      result = $col.find({block: target})
      result.each do |doc|
        if doc[:block][2] == target
          blocks.push(doc[:block])
        end
      end

      return blocks
    end

    def findBlocksBack(target)
      blocks = []

      result = $col.find({block: target})
      result.each do |doc|
        if doc[:block][0] == target
          blocks.push(doc[:block])
        end
      end

      return blocks
    end

    def findBlocks(target)
      blocks = []

      result = $col.find({block: target})
      result.each do |doc|
        blocks.push(doc[:block])
        p doc[:block]
      end

      return blocks
    end

    def connectBlockFront(array, dist)
      part_of_dist = []

      i = 0
      
      block = array[rand(array.length)]

      for word in block
        if i != 2 or word == -1 # 最後の被り要素を除く
          part_of_dist.unshift(word)
        end
        i += 1
      end

      for word in part_of_dist
        dist.unshift(word)
      end

      return dist
    end

    def connectBlockBack(array, dist, first_time=false)
      part_of_dist = []

      i = 0

      block = array[rand(array.length)]
      for word in block
        if i != 0 or word == -1 # 先頭の被り要素を除く
          part_of_dist.push(word)
        end
        i += 1
      end

      for word in part_of_dist
        dist.push(word)
      end

      return dist
    end
end

# ===================================================
# 汎用関数
# ===================================================
def generate_text_from_json(keyword, dir)
  markov = Markov.new

  tweet = ""
  
  # 140字に収まる文章が練成できるまでマルコフ連鎖する
  while tweet.length == 0 or tweet.length > 140 do
    begin
      tweetwords = markov.markov(keyword)
      if tweetwords == -1
        raise RuntimeError
      end
    rescue RuntimeError
      p "================================="
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
