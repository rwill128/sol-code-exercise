# frozen_string_literal: true

require('rubygems/text')
require('set')
include Gem::Text

dictionary = IO.readlines('words.txt').map(&:chomp).to_set

if ARGV.length.zero?
  puts 'No words provided, picking two random words from dictionary.'
  starting_word = dictionary.to_a.sample
  puts "Starting word is #{starting_word}"
  target_word = dictionary.to_a.sample
  puts "Target word is #{target_word}"
elsif (ARGV.length == 2) && dictionary.include?(ARGV[0]) && dictionary.include?(ARGV[1])
  starting_word = ARGV[0]
  target_word = ARGV[1]
else
  abort('Incorrect arguments provided. Either provide no arguments, or two arguments that are valid words.')
end
chain = []
attempted_words = Set.new

next_step = starting_word.dup
while next_step != target_word

  possible_steps = []

  # Possible Deletions
  cut_off_beginning = next_step[1..next_step.length - 1]
  possible_steps.append(cut_off_beginning) if dictionary.include?(cut_off_beginning) and !possible_steps.include?(cut_off_beginning)
  (1..next_step.length - 2).each do |i|
    deletion = next_step[0..i - 1] + next_step[i + 1..next_step.length - 1]
    possible_steps.append(deletion) if dictionary.include?(deletion) and !possible_steps.include?(deletion)
  end
  cut_off_end = next_step[0..next_step.length - 2]
  possible_steps.append(cut_off_end) if dictionary.include?(cut_off_end) and possible_steps.include?(cut_off_end)

  # Possible Insertions and Replacements
  (0..next_step.length - 1).each do |i|
    ('a'..'z').each do |letter|
      # The possible insertion at this index
      insertion_temp_var = next_step.dup
      insertion_temp_var.insert(i, letter)
      possible_steps.append(insertion_temp_var) if dictionary.include?(insertion_temp_var) and !possible_steps.include?(insertion_temp_var)

      # The possible replacement at this index
      replacement_temp_var = next_step.dup
      replacement_temp_var[i] = letter
      possible_steps.append(replacement_temp_var) if dictionary.include?(replacement_temp_var) and !possible_steps.include?(replacement_temp_var)
    end
  end

  # Find every word we haven't attempted yet
  real_possible_steps = (possible_steps.to_set - attempted_words).to_a

  # We have possible leaves that we haven't tried yet
  if !real_possible_steps.empty?
    attempted_words.add(next_step)
    chain.append(next_step)
    puts "Extending the chain to #{chain}"
    # For every word we haven't attempted yet, find the levenshtein distance from our target word
    step_scores = real_possible_steps.map { |step| levenshtein_distance(step, target_word) }
    # Pick the word that gets us closer
    next_step = real_possible_steps[step_scores.each_with_index.min.last]
  else
    if chain.length == 1
      abort("After exploring every leaf on the starting word graph, we have not found the target word. #{attempted_words.map { |word| "#{word} - #{levenshtein_distance(word, target_word)}" }}")
    end
    # We've tried all leaves, shave off the current word in our chain
    # and explore any unexplored leaves that branch off the previous word
    chain.delete_at(chain.length - 1)
    next_step = chain[chain.length - 1]
    puts "Going up a node to #{chain}"
  end
end

chain.append(next_step)

score_history = chain.map { |word| "#{word} - #{levenshtein_distance(word, target_word)}" }

puts score_history
