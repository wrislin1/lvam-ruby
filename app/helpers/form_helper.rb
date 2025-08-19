# frozen_string_literal: true

module FormHelper
  def dynamic_fields_for(f, association, name: "Add", add_button: true, id: "__CHILD_INDEX__", template_record: nil, container_classes: "", group_classes: "", add_action: "", button_classes: [])
    tag.div class: "flex flex-col #{container_classes}", data: { controller: "dynamic-fields" } do
      safe_join(
        [
          # render existing fields
          f.fields_for(association) do |ff|
            tag.div class: "nested-fields #{group_classes}" do
              yield ff
            end
          end,

          # render "Add" button that will call `add()` function
          # stimulus:         `add(event)` v
          *(if add_button
              [
                button_tag(type: "button", data: { action: "dynamic-fields#add #{add_action}" }, class: SecondaryButtonComponent::CLASSES + ButtonComponent::DEFAULT_CLASSES + button_classes + %w[py-2 px-3]) do
                  safe_join([ tag.i(class: "far fa-plus mr-1"), name ])
                end
              ]
            else
              []
            end),

          # render "<template>"
          # stimulus:           `this.templateTarget` v
          tag.template(data: { dynamic_fields_target: "template" }) do
            f.fields_for(association, template_record || association.to_s.classify.constantize.new, child_index: id) do |ff|
              tag.div class: "nested-fields" do
                yield ff
              end
            end
          end
        ]
      )
    end
  end
end
