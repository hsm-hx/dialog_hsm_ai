require './markov.rb'
require 'socket'

def main()
  # 会話文を生成
  sentence = generate_text_from_json(keyword, "")

  return sentence
end

main()
