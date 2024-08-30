// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

using System;
using System.Text.Json;
using AutoRest.CSharp.Common.Output.Expressions.KnownValueExpressions.Azure;
using AutoRest.CSharp.Common.Output.Expressions.ValueExpressions;
using static AutoRest.CSharp.Common.Output.Models.Snippets;
using AutoRest.CSharp.Generation.Types;

namespace AutoRest.CSharp.Common.Output.Expressions.KnownValueExpressions
{
    internal sealed record BinaryDataExpression(ValueExpression Untyped) : TypedValueExpression<BinaryData>(Untyped)
    {
        public FrameworkTypeExpression ToObjectFromJson(Type responseType)
            => new(responseType, new InvokeInstanceMethodExpression(Untyped, nameof(BinaryData.ToObjectFromJson), Array.Empty<ValueExpression>(), new[] { new CSharpType(responseType) }, false));

        public FrameworkTypeExpression MyToObjectFromJson(Type responseType, string name)
            => new(responseType, new InvokeInstanceMethodExpression(Untyped, name, Array.Empty<ValueExpression>(), new[] { new CSharpType(responseType) }, false));

        public FrameworkTypeExpression MyToObjectFromJsonString() {
            // We're going to bulid up an expression that calls Utf8JsonReader directly instead of going through BinaryData.ToObjectFromJson
            // Content (is BinaryData)
            // The final expression should look like this:
            // new Utf8JsonReader(Content.ToMemory().Span).GetString()
            var toMemoryExpression = ToMemory();
            var spanExpression = toMemoryExpression.Property(nameof(ReadOnlyMemory<byte>.Span));
            var utf8JsonReaderExpression = New.Instance(typeof(Utf8JsonReader), new[] { spanExpression });
            var getStringExpression = utf8JsonReaderExpression.Invoke(nameof(Utf8JsonReader.GetString));
            // => new(typeof(string), new InvokeInstanceMethodExpression(Untyped, "SVEN8", Array.Empty<ValueExpression>(), new[] { new CSharpType(typeof(string)) }, false));
            return new(typeof(string), getStringExpression);
        }

        public static BinaryDataExpression FromStream(StreamExpression stream, bool async)
        {
            var methodName = async ? nameof(BinaryData.FromStreamAsync) : nameof(BinaryData.FromStream);
            return new BinaryDataExpression(InvokeStatic(methodName, stream, async));
        }

        public static BinaryDataExpression FromStream(ValueExpression stream, bool async)
        {
            var methodName = async ? nameof(BinaryData.FromStreamAsync) : nameof(BinaryData.FromStream);
            return new(InvokeStatic(methodName, stream, async));
        }

        public ValueExpression ToMemory() => Invoke(nameof(BinaryData.ToMemory));

        public StreamExpression ToStream() => new(Invoke(nameof(BinaryData.ToStream)));

        public ListExpression ToArray() => new(typeof(byte[]), Invoke(nameof(BinaryData.ToArray)));

        public static BinaryDataExpression FromBytes(ValueExpression data)
            => new(InvokeStatic(nameof(BinaryData.FromBytes), data));

        public static BinaryDataExpression FromObjectAsJson(ValueExpression data)
            => new(InvokeStatic(nameof(BinaryData.FromObjectAsJson), data));

        public static BinaryDataExpression FromString(ValueExpression data)
            => new(InvokeStatic(nameof(BinaryData.FromString), data));
    }
}
