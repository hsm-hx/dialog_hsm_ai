require './markov.rb'
require 'socket'

def main()
  if (ARGV[0] and ARGV[1]) != nil 
    keyword = [ARGV[0], ARGV[1].to_i]
  else
    keyword = -1
  end

  # 会話文を生成
  sentence = generate_text_from_json(keyword, "")

  return sentence
end

main()
