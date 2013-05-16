module MotionWiretap
  class ControlEventNotFound < Exception
  end

  # Some UIControlEvent translators.  Based on SugarCube's uicontroleevent
  # constants.
  module ControlEvents
    module_function

    def convert(control_events)
      return control_events if control_events.is_a? Fixnum

      case control_events
      when NSArray
        retval = 0
        control_events.each do |event|
          begin
            retval |= ControlEvents.convert(event)
          rescue ControlEventNotFound
            raise "Could not merge control event #{event.inspect}"
          end
        end
        return retval
      when :touch
        return UIControlEventTouchUpInside
      when :touch_up
        return UIControlEventTouchUpInside
      when :touch_down
        return UIControlEventTouchDown
      when :touch_start
        return UIControlEventTouchDown | UIControlEventTouchDragEnter
      when :touch_stop
        return UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchDragExit
      when :change
        return UIControlEventValueChanged | UIControlEventEditingChanged
      when :begin
        return UIControlEventEditingDidBegin
      when :end
        return UIControlEventEditingDidEnd
      when :touch_down_repeat
        return UIControlEventTouchDownRepeat
      when :touch_drag_inside
        return UIControlEventTouchDragInside
      when :touch_drag_outside
        return UIControlEventTouchDragOutside
      when :touch_drag_enter
        return UIControlEventTouchDragEnter
      when :touch_drag_exit
        return UIControlEventTouchDragExit
      when :touch_up_inside
        return UIControlEventTouchUpInside
      when :touch_up_outside
        return UIControlEventTouchUpOutside
      when :touch_cancel
        return UIControlEventTouchCancel
      when :value_changed
        return UIControlEventValueChanged
      when :editing_did_begin
        return UIControlEventEditingDidBegin
      when :editing_changed
        return UIControlEventEditingChanged
      when :editing_did_change
        return UIControlEventEditingChanged
      when :editing_did_end
        return UIControlEventEditingDidEnd
      when :editing_did_end_on_exit
        return UIControlEventEditingDidEndOnExit
      when :all_touch
        return UIControlEventAllTouchEvents
      when :all_editing
        return UIControlEventAllEditingEvents
      when :application
        return UIControlEventApplicationReserved
      when :system
        return UIControlEventSystemReserved
      when :all
        return UIControlEventAllEvents
      else
        raise ControlEventNotFound.new
      end
    end

  end
end
