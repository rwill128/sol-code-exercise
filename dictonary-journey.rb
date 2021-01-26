# frozen_string_literal: true

require('rubygems/text')
require('set')
include Gem::Text

dictionary = IO.readlines('words.txt').map(&:chomp).to_set
original_word = 'cat'
target_word = 'door'
chain = []
attempted_words = Set.new

next_step = original_word.dup
current_distance = levenshtein_distance(next_step, target_word)
while next_step != target_word
  attempted_words.add(next_step)
  chain.append(next_step)
  possible_steps = []

  # Possible Deletions
  possible_steps.append(next_step[1..next_step.length - 1]) if dictionary.include?(next_step[1..next_step.length - 1])
  (1..next_step.length - 2).each do |i|
    deletion = next_step[0..i - 1] + next_step[i + 1..next_step.length - 1]
    possible_steps.append(deletion) if dictionary.include?(deletion)
  end
  possible_steps.append(next_step[0..next_step.length - 2]) if dictionary.include?(next_step[0..next_step.length - 2])

  # Possible Insertions and Replacements
  (0..next_step.length - 1).each do |i|
    ('a'..'z').each do |letter|
      # The possible insertion at this index
      possible_steps.append(next_step.dup.insert(i, letter)) if dictionary.include?(next_step.dup.insert(i, letter))

      # The possible replacement at this index
      replacement_temp_var = next_step.dup
      replacement_temp_var[i] = letter
      possible_steps.append(replacement_temp_var) if dictionary.include?(replacement_temp_var)
    end
  end

  # Find every word we haven't attempted yet
  real_possible_steps = (possible_steps.to_set - attempted_words).to_a

  # We have possible choices that we haven't
  if !real_possible_steps.empty?
    # For every word we haven't attempted yet, find the levenshtein distance from our target word
    step_scores = real_possible_steps.map { |step| levenshtein_distance(step, target_word) }
    # Pick the word that gets us closer
    next_step = real_possible_steps[step_scores.each_with_index.min.last]
  else
    if chain.length.zero?
      abort('After exploring every leaf on the starting word graph, we have not found the target word.')
    end
    chain.delete_at(chain.length - 1)
    next_step = chain[chain.length - 1]
  end
end

chain.append(next_step)

score_history = chain.map { |word| "#{word} - #{levenshtein_distance(word, target_word)}" }

puts score_history