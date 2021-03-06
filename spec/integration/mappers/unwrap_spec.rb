require 'spec_helper'

describe 'Mapper definition DSL' do
  include_context 'users and tasks'

  let(:header) { mapper.header }

  describe 'unwrapping relation mapper' do
    before do
      setup.relation(:tasks) do
        def with_user
          tuples = map { |tuple|
            tuple.merge(user: users.restrict(name: tuple[:name]).first)
          }

          self.class.new(tuples)
        end
      end

      setup.relation(:users)

      setup.mappers do
        define(:tasks) do
          model name: 'Test::Task'

          attribute :title
          attribute :priority
        end
      end
    end

    it 'unwraps nested attributes via options hash' do
      setup.mappers do
        define(:with_user, parent: :tasks) do
          attribute :title
          attribute :priority

          unwrap user: [:email, :name]
        end
      end

      rom = setup.finalize

      result = rom.relation(:tasks).with_user.as(:with_user).to_a.last

      expect(result).to eql(title: 'be cool',
                            priority: 2,
                            name: 'Jane',
                            email: 'jane@doe.org')
    end

    it 'unwraps nested attributes via options block' do
      setup.mappers do
        define(:with_user, parent: :tasks) do
          attribute :title
          attribute :priority

          unwrap :user do
            attribute :name
            attribute :user_email, from: :email
          end
        end
      end

      rom = setup.finalize

      result = rom.relation(:tasks).with_user.as(:with_user).to_a.last

      expect(result).to eql(title: 'be cool',
                            priority: 2,
                            name: 'Jane',
                            user_email: 'jane@doe.org')
    end

    it 'unwraps specified attributes via options block' do
      setup.mappers do
        define(:with_user, parent: :tasks) do
          attribute :title
          attribute :priority

          unwrap :contact, from: :user do
            attribute :task_user_name, from: :name
          end
        end
      end

      rom = setup.finalize

      result = rom.relation(:tasks).with_user.as(:with_user).to_a.last

      expect(result).to eql(title: 'be cool',
                            priority: 2,
                            name: 'Jane',
                            task_user_name: 'Jane',
                            contact: { email: 'jane@doe.org' })
    end
  end
end
