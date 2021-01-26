# frozen_string_literal: true

require('rubygems/text')
require('set')
include Gem::Text

dictionary = IO.readlines('words.txt').map(&:chomp).to_set

if ARGV.length.zero?
  puts 'No words provided, picking two random words from dictionary.'
  word_one = dictionary.to_a.sample
  puts "Word one is #{word_one}"
  word_two = dictionary.to_a.sample
  puts "Word two is #{word_two}"
elsif (ARGV.length == 2) && dictionary.include?(ARGV[0]) && dictionary.include?(ARGV[1])
  word_one = ARGV[0]
  word_two = ARGV[1]
else
  abort('Incorrect arguments provided. Either provide no arguments, or two arguments that are valid words.')
end

word_one_copy_one =  word_one.dup
word_two_copy_one =  word_two.dup

word_one_copy_two =  word_one.dup
word_two_copy_two =  word_two.dup

starting_word_search = Thread.new do
  chain = []
  attempted_words = Set.new

  next_step = word_one_copy_one.dup
  while next_step != word_two_copy_one

    possible_steps = []

    # Possible Deletions
    cut_off_beginning = next_step[1..next_step.length - 1]
    if dictionary.include?(cut_off_beginning) && !possible_steps.include?(cut_off_beginning)
      possible_steps.append(cut_off_beginning)
    end
    (1..next_step.length - 2).each do |i|
      deletion = next_step[0..i - 1] + next_step[i + 1..next_step.length - 1]
      possible_steps.append(deletion) if dictionary.include?(deletion) && !possible_steps.include?(deletion)
    end
    cut_off_end = next_step[0..next_step.length - 2]
    possible_steps.append(cut_off_end) if dictionary.include?(cut_off_end) && possible_steps.include?(cut_off_end)

    # Possible Insertions and Replacements
    (0..next_step.length - 1).each do |i|
      ('a'..'z').each do |letter|
        # The possible insertion at this index
        insertion_temp_var = next_step.dup
        insertion_temp_var.insert(i, letter)
        if dictionary.include?(insertion_temp_var) && !possible_steps.include?(insertion_temp_var)
          possible_steps.append(insertion_temp_var)
        end

        # The possible replacement at this index
        replacement_temp_var = next_step.dup
        replacement_temp_var[i] = letter
        if dictionary.include?(replacement_temp_var) && !possible_steps.include?(replacement_temp_var)
          possible_steps.append(replacement_temp_var)
        end
      end
    end

    # Find every word we haven't attempted yet
    real_possible_steps = (possible_steps.to_set - attempted_words).to_a

    # We have possible leaves that we haven't tried yet
    if !real_possible_steps.empty?
      attempted_words.add(next_step)
      chain.append(next_step)
      # system('clear') || system('cls')
      puts "Forward search. Extending the chain to #{chain.last}. Starting word was #{word_one_copy_one}. Target word is #{word_two_copy_one}. Distance is #{levenshtein_distance(
        chain.last, word_two_copy_one
      )}."
      # For every word we haven't attempted yet, find the levenshtein distance from our target word
      step_scores = real_possible_steps.map { |step| levenshtein_distance(step, word_two_copy_one) }
      # Pick the word that gets us closer
      next_step = real_possible_steps[step_scores.each_with_index.min.last]
    else
      if chain.length == 1
        abort("Forward search. After exploring every leaf on the starting word graph, we have not found the target word. #{attempted_words.map do |word|
                                                                                                                             "#{word} - #{levenshtein_distance(
                                                                                                                               word, word_two_copy_one
                                                                                                                             )}"
                                                                                                                           end }")
      end
      # We've tried all leaves, shave off the current word in our chain
      # and explore any unexplored leaves that branch off the previous word
      chain.delete_at(chain.length - 1)
      next_step = chain[chain.length - 1]
      # system('clear') || system('cls')
      puts "Forward search. Going up a node to #{chain.last}. Starting word was #{word_one_copy_one}. Target word is #{word_two_copy_one}. Distance is #{levenshtein_distance(
        chain.last, word_two_copy_one
      )}."
    end
  end

  chain.append(next_step)

  score_history = chain.map { |word| "#{word} - #{levenshtein_distance(word, word_two_copy_one)}" }

  puts "Forward search. Chain is #{score_history.uniq.length} items long. This is the search chain: #{score_history.uniq}"
end

target_word_search = Thread.new do
  chain = []
  attempted_words = Set.new

  # Intentionally switching these to search from the other side. If either thread aborts, they both can.
  next_step = word_two_copy_two.dup
  target_word = word_one_copy_two

  while next_step != target_word

    possible_steps = []

    # Possible Deletions
    cut_off_beginning = next_step[1..next_step.length - 1]
    if dictionary.include?(cut_off_beginning) && !possible_steps.include?(cut_off_beginning)
      possible_steps.append(cut_off_beginning)
    end
    (1..next_step.length - 2).each do |i|
      deletion = next_step[0..i - 1] + next_step[i + 1..next_step.length - 1]
      possible_steps.append(deletion) if dictionary.include?(deletion) && !possible_steps.include?(deletion)
    end
    cut_off_end = next_step[0..next_step.length - 2]
    possible_steps.append(cut_off_end) if dictionary.include?(cut_off_end) && possible_steps.include?(cut_off_end)

    # Possible Insertions and Replacements
    (0..next_step.length - 1).each do |i|
      ('a'..'z').each do |letter|
        # The possible insertion at this index
        insertion_temp_var = next_step.dup
        insertion_temp_var.insert(i, letter)
        if dictionary.include?(insertion_temp_var) && !possible_steps.include?(insertion_temp_var)
          possible_steps.append(insertion_temp_var)
        end

        # The possible replacement at this index
        replacement_temp_var = next_step.dup
        replacement_temp_var[i] = letter
        if dictionary.include?(replacement_temp_var) && !possible_steps.include?(replacement_temp_var)
          possible_steps.append(replacement_temp_var)
        end
      end
    end

    # Find every word we haven't attempted yet
    real_possible_steps = (possible_steps.to_set - attempted_words).to_a

    # We have possible leaves that we haven't tried yet
    if !real_possible_steps.empty?
      attempted_words.add(next_step)
      chain.append(next_step)
      # system('clear') || system('cls')
      puts "Backward search. Extending the chain to #{chain.last}. Starting word was #{word_two_copy_two}. Target word is #{word_one_copy_two}. Distance is #{levenshtein_distance(
        chain.last, word_one_copy_two
      )}."
      # For every word we haven't attempted yet, find the levenshtein distance from our target word
      step_scores = real_possible_steps.map { |step| levenshtein_distance(step, target_word) }
      # Pick the word that gets us closer
      next_step = real_possible_steps[step_scores.each_with_index.min.last]
    else
      if chain.length == 1
        abort("Backward search. After exploring every leaf on the starting word graph, we have not found the target word. #{attempted_words.map do |word|
                                                                                                                              "#{word} - #{levenshtein_distance(
                                                                                                                                word, word_one_copy_two
                                                                                                                              )}"
                                                                                                                            end }")
      end
      # We've tried all leaves, shave off the current word in our chain
      # and explore any unexplored leaves that branch off the previous word
      chain.delete_at(chain.length - 1)
      next_step = chain[chain.length - 1]
      # system('clear') || system('cls')
      puts "Backward search. Going up a node to #{chain.last}. Starting word was #{word_two_copy_two}. Target word is #{word_one_copy_two}. Distance is #{levenshtein_distance(
        chain.last, word_one_copy_two
      )}."
    end
  end

  chain.append(next_step)

  score_history = chain.map { |word| "#{word} - #{levenshtein_distance(word, word_one_copy_two)}" }

  "Backward search. Chain is #{score_history.uniq.length} items long. This is the search chain: #{score_history.uniq}"
end

puts 'Getting value on forward search.'
puts starting_word_search.value

puts 'Getting value on backward search.'
puts target_word_search.value

puts 'Both threads finished.'
