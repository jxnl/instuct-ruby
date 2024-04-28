# gem 'instructor-rb'
require 'instructor'

OpenAI.configure do |config|
  config.access_token = ENV.fetch("OPENAI_API_KEY")
end

class Category
  include EasyTalk::Model

  define_schema do
    property :topic, String
    property :tags, T::Array[String]
    property :title, String
  end
end

client = Instructor.patch(OpenAI::Client).new(access_token: ENV['OPENAI_API_KEY'])

def classify_conversation(client, capabilities, conversation)
  prompt = <<~PROMPT
    Given the following conversation, classify it into one of the existing categories based on the nature of the interaction and the capabilities demonstrated by the AI assistant. If the conversation does not fit well into any of the predefined categories, suggest a new topic and relevant tags for the category. Additionally, provide a short title (less than 10 words) that summarizes the conversation.
    Existing Categories:
    <capabilities>
    #{capabilities.to_json}
    </capabilities>
    Conversation:
    <conversation>
    #{conversation}
    </conversation>
    If the conversation fits into an existing category, provide the following:
    - Topic: [Topic of the matching category]
    - Tags: [Relevant tags from the matching category, allowed to create new tags]
    - Title: [A short descriptive and specific title summarizing the conversation in less than 10 words]
    If the conversation does not fit well into any existing category, provide the following:
    - Topic: [Proposed topic for the new category in snake_case]
    - Tags: [Proposed tags for the new category in snake_case, separated by commas]
    - Title: [A short descriptive and specific title summarizing the conversation in less than 10 words]
  PROMPT

  response = client.chat(
    parameters: {
      model: "gpt-3.5-turbo-0613",
      messages: [
        {
          "role": "system",
          "content": "You are an AI assistant that can classify conversations into categories.",
        },
        {
          "role": "user",
          "content": prompt,
        },
      ],
    },
    response_model: Category
  )
  return response
end

capabilities = {
  "capabilities": [
    {
      "topic": "language_understanding",
      "potential_tags": [
        "sentiment_analysis",
        "text_classification",
        "topic_identification",
        "toxicity_detection",
      ],
      "examples": [
        "I just read this user review and I'm curious what you think the overall sentiment is?",
        "I have this article that needs to be categorized. Could you help me figure out which of the predefined categories it belongs to?",
        "I'm trying to get the gist of this paragraph. What would you say is the main topic or subject it's discussing?",
        "Can you take a look at this social media post and let me know if you spot any language that comes across as toxic or offensive?",
      ],
    },
    {
      "topic": "language_generation",
      "potential_tags": [
        "text_summarization",
        "creative_writing",
        "simplification",
        "dialogue_generation",
      ],
      "examples": [
        "I have a long article here that I need to get the key points from. Could you give me a concise summary in just a few sentences?",
        "I'd love to get my creative juices flowing. Can you write me an engaging short story based on this writing prompt I have?",
        "This legal document is full of complex jargon. Would you mind rephrasing it in plain, easy-to-understand terms for me?",
        "I'm trying to imagine how people would discuss current events. Could you create a sample dialogue between two characters talking about a recent news story?",
      ],
    },
    {
      "topic": "reasoning",
      "potential_tags": [
        "inference",
        "problem_solving",
        "causal_analysis",
        "decision_making",
      ],
      "examples": [
        "I've shared some key facts about the situation. What insights can you draw from them?",
        "This is a tricky logical reasoning puzzle. Can you walk me through how to approach solving it step-by-step?",
        "Let's look at this historical event more closely. How would you break down the causal relationships between what happened?",
        "I'm facing a real ethical dilemma here and I'm not sure what to do. Based on the details I provided, what do you think is the right path forward?",
      ],
    },
    {
      "topic": "knowledge_and_factuality",
      "potential_tags": [
        "historical_events",
        "health_and_nutrition",
        "science_and_technology",
        "political_systems",
      ],
      "examples": [
        "Provide a brief overview of the key events in World War II.",
        "What are the main components of a healthy diet according to nutritional guidelines?",
        "Explain the fundamental principles of quantum mechanics in simple terms.",
        "Compare and contrast the features of capitalism and socialism.",
      ],
    },
    {
      "topic": "multilingualism",
      "potential_tags": [
        "translation",
        "language_identification",
        "language_learning",
        "grammar_and_structure",
      ],
      "examples": [
        "Translate this English sentence into French, German, and Italian.",
        "Identify the language of this user input and provide an appropriate response in the same language.",
        "Generate a language learning lesson to teach basic vocabulary in Mandarin Chinese.",
        "Explain the main grammatical differences between English and Japanese sentence structures.",
      ],
    },
  ]
}

conversation = "I have this article that needs to be categorized. Could you help me figure out which of the predefined categories it belongs to?"
classification = classify_conversation(client, capabilities, conversation)

puts classification.to_json