require 'instructor'

OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY")
end

class NewCategory
  include EasyTalk::Model
  define_schema do
    description "This is a class representing a classification error. Only utilise this if we are unable to categorize the user's query"
    property :Message, String, description: "Explain why it is not possible to categorize the user's query according to the pre-defined set of categories"
    property :Topic, String, description: "Proposed topic for the new category in snake_case"
    property :Tag, T::Array[String], description: "Proposed tags for the new category in snake_case, separated by commas"
    property :Title, String, description:  "A short descriptive and specific title summarizing the conversation in less than 10 words"
  end
end

class LanguageUnderstanding
  include EasyTalk::Model

  define_schema do
    description <<-DESC
      Examples of queries that should be matched to Language Understanding include
      - I just read this user review and I'm curious what you think the overall sentiment is?
      - I have this article that needs to be categorized. Could you help me figure out which of the predefined categories it belongs to?
      - I'm trying to get the gist of this paragraph. What would you say is the main topic or subject it's discussing?
      - Can you take a look at this social media post and let me know if you spot any language that comes across as toxic or offensive?
    DESC
    title "language_understanding"
    property :Tags, T::Array[String], description: <<-DESC
    Some potential tags that might be generated for a language_understanding task include
      -sentiment_analysis
      -text_classification
      -topic_identification
      -toxicity_detection
    
    You are allowed to create new tags. Generate at least
    DESC
    property :Topic, String, enum: %w[language_understanding]
    property :Title, String, description: "A short descriptive and specific title summarizing the conversation in less than 10 words"
  end
end

class LanguageGeneration
  include EasyTalk::Model

  define_schema do
    description <<-DESC
    Examples of queries that should be matched to Language Generation include
      - I have a long article here that I need to get the key points from. Could you give me a concise summary in just a few sentences?,
      - I'd love to get my creative juices flowing. Can you write me an engaging short story based on this writing prompt I have?,
      - This legal document is full of complex jargon. Would you mind rephrasing it in plain, easy-to-understand terms for me?,
      - I'm trying to imagine how people would discuss current events. Could you create a sample dialogue between two characters talking about a recent news story?,
    DESC
    title "language_generation"
    property :Tags, T::Array[String], description: <<-DESC
    Some potential tags that might be generated for a language_understanding task include
      - text_summarization
      - creative_writing
      - simplification
      - dialogue_generation
    
    You are allowed to create new tags. Generate at least
    DESC
    property :Topic, String, enum: %w[language_generation], default: "language_generation"
    property :Title, String, description: "A short descriptive and specific title summarizing the conversation in less than 10 words"
  end
end

class Reasoning
  include EasyTalk::Model

  define_schema do
    description <<-DESC
    Examples of queries that should be matched to Reasoning include
    - I've shared some key facts about the situation. What insights can you draw from them?
    - This is a tricky logical reasoning puzzle. Can you walk me through how to approach solving it step-by-step?
    - Let's look at this historical event more closely. How would you break down the causal relationships between what happened?
    - I'm facing a real ethical dilemma here and I'm not sure what to do. Based on the details I provided, what do you think is the right path forward?
    DESC
    title "reasoning"
    property :Tags, T::Array[String], description: <<-DESC
    Some potential tags that might be generated for a reasoning task include
      - inference
      - problem_solving
      - causal_analysis
      - decision_making
    
    You are allowed to create new tags. Generate at least
    DESC
    property :Topic, String, enum: %w[reasoning], default: "reasoning"
    property :Title, String, description: "A short descriptive and specific title summarizing the conversation in less than 10 words"
  end
end

class KnowledgeAndFactuality
  include EasyTalk::Model

  define_schema do
    description <<-DESC
    Examples of queries that should be matched to Knowledge and Factuality include
    - Provide a brief overview of the key events in World War II
    - What are the main components of a healthy diet according to nutritional guidelines
    - Explain the fundamental principles of quantum mechanics in simple terms
    - Compare and contrast the features of capitalism and socialism
    DESC
    title "knowledge_and_factuality"
    property :Tags, T::Array[String], description: <<-DESC
    Some potential tags that might be generated for a knowledge and factuality task include
      - historical_events
      - health_and_nutrition
      - science_and_technology
      - political_systems
    
    You are allowed to create new tags. Generate at least
    DESC
    property :Topic, String, enum: %w[knowledge_and_factuality], default: "knowledge_and_factuality"
    property :Title, String, description: "A short descriptive and specific title summarizing the conversation in less than 10 words"
  end
end

class Multilingualism
  include EasyTalk::Model
  define_schema do
    description <<-DESC
    Examples of queries that should be matched to Multilingualism include
    - Translate this English sentence into French, German, and Italian.
    - Identify the language of this user input and provide an appropriate response in the same language.
    - Generate a language learning lesson to teach basic vocabulary in Mandarin Chinese.
    - Explain the main grammatical differences between English and Japanese sentence structures.
    DESC
    title "reasoning"
    property :Tags, T::Array[String], description: <<-DESC
    Some potential tags that might be generated for a language_understanding task include
      - translation
      - language_identification
      - language_learning
      - grammar_and_structure
    

    You are allowed to create new tags. Generate at least
    DESC
    property :Topic, String, enum: %w[multilingualism], default: "multilingualism"
    property :Title, String, description: "A short descriptive and specific title summarizing the conversation in less than 10 words"
  end

end

class Category
  include EasyTalk::Model
  define_schema do 
    description "This is a Schema class which represents a classification of a user's query according to a pre-defined set of categories if possible. Otherwise set error as true and briefly explain why this is the case in the Error class."
    property :chain_of_thought, String, description:"Think step by step to determine the correct category to classify the user's query as"
    property :error, T::Boolean, default:false, description:"This is a boolean that indicates if we encountered any errors while trying to classify the user's query"
    property :category, T::OneOf[NewCategory,LanguageGeneration,LanguageUnderstanding,Reasoning,KnowledgeAndFactuality,Multilingualism]
  end 
end






def classify_conversation(conversation,client)
  for attempt in 1..3
    begin
      response = client.chat(
        parameters: {
          model: 'gpt-3.5-turbo',
          messages: [
            {
              "role": "system",
              "content": "You are an AI assistant that can classify conversations into categories.",
            },
            {
              "role": "assistant",
              "content": "You are about to be given a user query to classify. Make sure to classify it into one of the existing categories as defined in the schema provided and based on the nature of the interaction and the capabilities demonstrated by the AI assistant. If the conversation does not fit well into any of the predefined categories, suggest a new topic and relevant tags for the category. Additionally, provide a short title (less than 10 words) that summarizes the conversation."
            },
            {
              "role":"user",
              "content":conversation
            }
          ]
        },
        response_model: Category,
      )
      return response unless response.error
    rescue => e
      raise if attempt == 3
    end
  end
end

test_examples = [
  ["I have this article that needs to be categorized. Could you help me figure out which of the predefined categories it belongs to?",'language_understanding'],
  ["What are some useful phrases to know when travelling to France?",'multilingualism'],
  ["Can you briefly summarize what are some of the challenges facing the new Biden Administration?",'knowledge_and_factuality'],
  ["Can you help me generate a short story based in Shanghai?",'language_generation'],
  ["What is the overall sentiment in the sence 'I LOVE GPT'?",'language_understanding'],
]
client = Instructor.patch(OpenAI::Client).new
test_examples.each do |example, expected_category|
  result = classify_conversation(example,client)
  print("Classification was #{result.category}\n")
  raise "Expected category '#{expected_category}', but got '#{result.category["Topic"]}'" unless result.category["Topic"] == expected_category
end

