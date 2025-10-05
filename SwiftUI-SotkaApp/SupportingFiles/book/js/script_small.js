//$("#divpage").load('top.html');

$(document).ready(
    function () {
        /* set day name to title*/
        var dayName = $('#fldDayName').val();
        if (dayName !== 'undefined') {
            $('title').text(dayName);
        }

        var st = unescape(window.location.href );
        var pageName = st.substring( st.lastIndexOf('/') + 1, st.length );

         $("head").append($("<link rel='stylesheet' href='../css/style_small.css' type='text/css' media='screen' />"));
    }
);