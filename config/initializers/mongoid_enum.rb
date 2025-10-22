require_relative '../../lib/mongoid/enum'

# Include the enum functionality in Mongoid::Document
Mongoid::Document.include Mongoid::Enum