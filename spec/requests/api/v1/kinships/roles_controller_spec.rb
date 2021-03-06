require 'swagger_helper'

RSpec.describe Api::V1::Kinships::RolesController, type: :request do
  let(:user) { create :user }
  let(:member) { create :user }
  let!(:family) { create :family, users: [user, member] }
  let(:kinship) { member.kinships.find_by(family: family) }
  let(:kinship_id) { kinship.id }

  path '/api/v1/kinships/{kinship_id}/role' do
    parameter name: 'kinship_id', in: :path, type: :string

    patch('update role') do
      include_context 'cookie'
      tags 'Role'

      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          role: { type: :string, enum: Kinship.roles.excluding('admin') }
        }
      }
      let(:payload) do
        {
          kinship: {
            role: 'co_admin'
          }
        }
      end
      before { stub_mandrill }

      response(200, 'successful', save_request_example: :payload) do
        run_test! do
          expect(response.parsed_body['data']['attributes']['role']).to eq('co_admin')
          expect(all_emails.map(&:subject)).to contain_exactly("Your Role Changed in #{family.name}")
        end
      end
    end
  end
end
