# typed: true

class Alchemrest::Result
  extend T::Generic

  ValueType = type_member(:out)

  sealed!
  abstract!

  sig do
    type_parameters(:Value)
      .params(value: T.type_parameter(:Value))
      .returns(Alchemrest::Result::Ok[T.type_parameter(:Value)])
  end
  def self.Ok(value); end

  sig { params(error: T.any(Exception, String)).returns(Alchemrest::Result::Error) }
  def self.Error(error); end

  sig do
    type_parameters(:ValueType)
      .params(
        block: T.proc.params(try: T.class_of(Alchemrest::Result::TryHelpers)).returns(
          T.any(Alchemrest::Result[T.type_parameter(:ValueType)], T.type_parameter(:ValueType)),
        ),
      )
      .returns(Alchemrest::Result[T.type_parameter(:ValueType)])
  end
  def self.for(&block); end

  sig { returns(T::Boolean) }
  def ok?; end

  sig { params(other: T.untyped).returns(T::Boolean) }
  def ==(other); end

  sig do
    type_parameters(:Result)
      .params(block: T.proc.params(value: ValueType).returns(T.type_parameter(:Result)))
      .returns(Alchemrest::Result[T.type_parameter(:Result)])
  end
  def transform(&block); end

  sig { returns(ValueType) }
  def unwrap_or_raise!; end

  sig do
    type_parameters(:Fallback)
      .params(block: T.proc.returns(T.type_parameter(:Fallback)))
      .returns(T.any(ValueType, T.type_parameter(:Fallback)))
  end
  def unwrap_or_rescue(&block); end
end

class Alchemrest::Result::Ok < Alchemrest::Result
  ValueType = type_member

  sig { params(value: ValueType).void }
  def initialize(value); end

  sig { returns([ValueType]) }
  def deconstruct; end

  sig { params(_keys: T.untyped).returns({ value: ValueType }) }
  def deconstruct_keys(_keys); end
end

class Alchemrest::Result::Error < Alchemrest::Result
  ValueType = type_member { { fixed: T.noreturn } }

  sig { params(error: T.any(String, Exception)).void }
  def initialize(error); end

  sig { returns([Exception]) }
  def deconstruct; end

  sig { params(_keys: T.untyped).returns({ error: Exception }) }
  def deconstruct_keys(_keys); end
end
